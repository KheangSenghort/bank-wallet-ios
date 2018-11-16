import UIKit
import SnapKit

struct TransactionFilterItem {
    let coin: Coin?
    let name: String
}

class TransactionsViewController: UITableViewController {

    let delegate: ITransactionsViewDelegate

    private let cellName = String(describing: TransactionCell.self)

    private let emptyLabel = UILabel()
    private let filterHeaderView = TransactionCurrenciesHeaderView()

    init(delegate: ITransactionsViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        tabBarItem = UITabBarItem(title: "transactions.tab_bar_item".localized, image: UIImage(named: "transactions.tab_bar_item"), tag: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        filterHeaderView.onSelectCoin = { coin in
            self.delegate.onFilterSelect(coin: coin)
        }

        tableView.backgroundColor = AppTheme.controllerBackground
        tableView.tableFooterView = UIView(frame: .zero)

        tableView.registerCell(forClass: TransactionCell.self)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 0
        tableView.delaysContentTouches = false

        let emptyView = UIView()
        emptyView.backgroundColor = .clear
        tableView.backgroundView = emptyView

        emptyLabel.text = "transactions_empty_text".localized
        emptyLabel.numberOfLines = 0
        emptyLabel.font = .systemFont(ofSize: 14)
        emptyLabel.textColor = .cryptoGray
        emptyLabel.textAlignment = .center
        emptyView.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(50)
            maker.trailing.equalToSuperview().offset(-50)
        }

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(onRefresh), for: .valueChanged)

        delegate.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @objc func onRefresh() {
        delegate.refresh()
    }

}

extension TransactionsViewController: ITransactionsView {

    func set(title: String) {
        self.title = title.localized
    }

    func show(filters: [TransactionFilterItem]) {
        filterHeaderView.reload(filters: filters)
    }

    func didRefresh() {
        refreshControl?.endRefreshing()
    }

    func reload() {
        tableView.reloadData()
    }

}

extension TransactionsViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = delegate.itemsCount

        emptyLabel.isHidden = count > 0

        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: cellName, for: indexPath)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? TransactionCell {
            cell.bind(item: delegate.item(forIndex: indexPath.row))
        }
    }

    override public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = delegate.item(forIndex: indexPath.row)
        delegate.onTransactionItemClick(transaction: item)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TransactionsTheme.cellHeight
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return TransactionsFilterTheme.filterHeaderHeight
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return filterHeaderView
    }

}
