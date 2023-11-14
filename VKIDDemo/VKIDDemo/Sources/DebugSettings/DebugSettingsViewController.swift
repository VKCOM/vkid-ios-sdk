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

import Foundation
import UIKit

final class DebugSettingsViewController: UITableViewController {
    private var viewModel = DebugSettingsViewModel(title: "DebugSettings", sections: [])

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(self.close(sender:))
        )

        self.tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: String(describing: UITableViewCell.self)
        )
    }

    @objc
    private func close(sender: AnyObject) {
        self.dismiss(animated: true)
    }

    func render(viewModel vm: DebugSettingsViewModel) {
        self.viewModel = vm
        self.title = vm.title
        self.tableView.reloadData()
    }

    // MARK: UITableViewDataSource & UITableViewDelegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        self.viewModel.sections.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        self.viewModel[section].title
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.viewModel[section].cells.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let vm = self.viewModel[indexPath]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: UITableViewCell.self),
            for: indexPath
        )
        cell.textLabel?.text = vm.title
        cell.accessoryType = vm.checked ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.viewModel[indexPath].action()
    }
}
