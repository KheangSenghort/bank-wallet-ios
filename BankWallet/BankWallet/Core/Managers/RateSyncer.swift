import RxSwift

class RateSyncer {
    private let refreshIntervalInMinutes: Double = 3

    private let disposeBag = DisposeBag()

    private let rateManager: IRateManager
    private let adapterManager: IAdapterManager
    private let currencyManager: ICurrencyManager
    private let reachabilityManager: IReachabilityManager

    init(rateManager: IRateManager, adapterManager: IAdapterManager, currencyManager: ICurrencyManager, reachabilityManager: IReachabilityManager) {
        self.rateManager = rateManager
        self.adapterManager = adapterManager
        self.currencyManager = currencyManager
        self.reachabilityManager = reachabilityManager

        let scheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        let timer = Observable<Int>.timer(0, period: refreshIntervalInMinutes * 60, scheduler: scheduler).map { _ in () }

        Observable.merge(adapterManager.adaptersUpdatedSignal, currencyManager.baseCurrencyUpdatedSignal, reachabilityManager.reachabilitySignal, timer)
                .subscribeOn(scheduler)
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] in
                    self?.syncLatestRates()
                })
                .disposed(by: disposeBag)

        Observable.merge(currencyManager.baseCurrencyUpdatedSignal, reachabilityManager.reachabilitySignal)
                .subscribeOn(scheduler)
                .observeOn(scheduler)
                .subscribe(onNext: { [weak self] in
                    self?.syncTimestampRates()
                })
                .disposed(by: disposeBag)

        syncTimestampRates()
    }

    private func syncLatestRates() {
        if reachabilityManager.isReachable {
            rateManager.refreshLatestRates(coinCodes: adapterManager.adapters.map { $0.coin.code }, currencyCode: currencyManager.baseCurrency.code)
        }
    }

    private func syncTimestampRates() {
        if reachabilityManager.isReachable {
            rateManager.syncZeroValueTimestampRates(currencyCode: currencyManager.baseCurrency.code)
        }
    }

}
