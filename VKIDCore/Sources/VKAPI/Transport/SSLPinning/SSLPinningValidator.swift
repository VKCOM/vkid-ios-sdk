//
// Copyright (c) 2023 - present, LLC “V Kontakte”
//
// 1. Permission is hereby granted to any person obtaining a copy of this Software to
// use the Software without charge.
//
// 2. Restrictions
// You may not modify, merge, publish, distribute, sublicense, and/or sell copies,
// create derivative works based upon the Software or any part thereof.
//
// 3. Termination
// This License is effective until terminated. LLC “V Kontakte” may terminate this
// License at any time without any negative consequences to our rights.
// You may terminate this License at any time by deleting the Software and all copies
// thereof. Upon termination of this license for any reason, you shall continue to be
// bound by the provisions of Section 2 above.
// Termination will be without prejudice to any rights LLC “V Kontakte” may have as
// a result of this agreement.
//
// 4. Disclaimer of warranty and liability
// THE SOFTWARE IS MADE AVAILABLE ON THE “AS IS” BASIS. LLC “V KONTAKTE” DISCLAIMS
// ALL WARRANTIES THAT THE SOFTWARE MAY BE SUITABLE OR UNSUITABLE FOR ANY SPECIFIC
// PURPOSES OF USE. LLC “V KONTAKTE” CAN NOT GUARANTEE AND DOES NOT PROMISE ANY
// SPECIFIC RESULTS OF USE OF THE SOFTWARE.
// UNDER NO CIRCUMSTANCES LLC “V KONTAKTE” BEAR LIABILITY TO THE LICENSEE OR ANY
// THIRD PARTIES FOR ANY DAMAGE IN CONNECTION WITH USE OF THE SOFTWARE.
//

import CommonCrypto
import Foundation

internal protocol SSLPinningValidating {
    func validateChallenge(_ challenge: URLAuthenticationChallenge) -> SSLPinningValidationResult
}

internal enum SSLPinningValidationResult {
    case trustedDomain(SecTrust)
    case domainNotPinned
    case noMatchingPins
    case failedToProcessServerCertificate
}

internal final class SSLPinningValidator: SSLPinningValidating {
    private let configuration: SSLPinningConfiguration

    internal init(configuration: SSLPinningConfiguration) {
        self.configuration = configuration
    }

    func validateChallenge(_ challenge: URLAuthenticationChallenge) -> SSLPinningValidationResult {
        guard self.configuration.isDomainPinned(challenge.protectionSpace.host) else {
            return .domainNotPinned
        }
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            return .failedToProcessServerCertificate
        }

        // Check each certificate in the server's certificate chain (the trust object); start with the CA all the way down to the leaf
        let certificateChainLength = SecTrustGetCertificateCount(serverTrust)
        for idx in (0..<certificateChainLength).reversed() {
            guard
                let cert = SecTrustGetCertificateAtIndex(serverTrust, idx),
                let publicKey = self.extractServerCertificatePublicKey(from: cert),
                let asn1Header = self.asn1HeaderMatching(
                    keyType: publicKey.type,
                    keySize: publicKey.size
                )
            else {
                continue
            }
            let pin = self.sha256(
                data: publicKey.data,
                header: asn1Header
            )
            if self.configuration.isValidPin(
                pin,
                for: challenge.protectionSpace.host
            ) {
                return .trustedDomain(serverTrust)
            }
        }
        return .noMatchingPins
    }

    private func extractServerCertificatePublicKey(
        from cert: SecCertificate
    ) -> ServerCertificatePublicKey? {
        guard
            // Transforming public key to Data and getting attributes.
            let publicKey = SecCertificateCopyKey(cert),
            let publicKeyData = SecKeyCopyExternalRepresentation(
                publicKey,
                nil
            ) as? Data,
            let publicKeyAttributes = SecKeyCopyAttributes(
                publicKey
            ) as? [AnyHashable: Any],
            // Extracting the type and size of the public key to find out which asn1 header to use.
            let publicKeyType = publicKeyAttributes[kSecAttrType] as? String,
            let publicKeySize = publicKeyAttributes[kSecAttrKeySizeInBits] as? Int
        else {
            return nil
        }
        return ServerCertificatePublicKey(
            type: publicKeyType,
            size: publicKeySize,
            data: publicKeyData
        )
    }

    private func asn1HeaderMatching(
        keyType: String,
        keySize: Int
    ) -> [UInt8]? {
        switch (keyType as CFString, keySize) {
        case (kSecAttrKeyTypeRSA, 2048): // rsa2048
            return [
                0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
                0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00,
            ]
        case (kSecAttrKeyTypeRSA, 4096): // rsa4096
            return [
                0x30, 0x82, 0x02, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
                0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0f, 0x00,
            ]
        case (kSecAttrKeyTypeECSECPrimeRandom, 256): // ecdsasecp256r1
            return [
                0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01,
                0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00,
            ]
        case (kSecAttrKeyTypeECSECPrimeRandom, 384): // ecdsasecp384r1
            return [
                0x30, 0x76, 0x30, 0x10, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
                0x01, 0x06, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x22, 0x03, 0x62, 0x00,
            ]
        default:
            return nil
        }
    }

    private func sha256(data: Data, header: [UInt8]) -> Data {
        var keyWithHeader = Data(header)
        keyWithHeader.append(data)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        keyWithHeader.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(keyWithHeader.count), &hash)
        }
        return Data(hash)
    }
}

private struct ServerCertificatePublicKey {
    fileprivate let type: String
    fileprivate let size: Int
    fileprivate let data: Data
}
