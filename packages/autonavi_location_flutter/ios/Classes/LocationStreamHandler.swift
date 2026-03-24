import Flutter

class LocationStreamHandler: NSObject, FlutterStreamHandler {

    private let adapter = AMapLocationAdapter()
    private var eventSink: FlutterEventSink?

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        adapter.onLocation = { [weak self] result in self?.eventSink?(result) }
        adapter.onError = { [weak self] err in
            self?.eventSink?(FlutterError(code: err.code, message: err.message, details: nil))
        }
        adapter.startContinuous(options: parseOptions(arguments as? [String: Any] ?? [:]))
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        adapter.stop()
        eventSink = nil
        return nil
    }

    // MARK: - Public

    func getOnce(options: [String: Any], callback: @escaping (Any?) -> Void) {
        adapter.startOnce(options: parseOptions(options)) { result, err in
            if let err = err {
                callback(FlutterError(code: err.code, message: err.message, details: nil))
            } else {
                callback(result)
            }
        }
    }

    func updateOptions(_ options: [String: Any]) {
        adapter.updateOptions(parseOptions(options))
    }

    // MARK: - Private

    private func parseOptions(_ options: [String: Any]) -> LocationOptions {
        return LocationOptions(
            accuracy: options["accuracy"] as? Int ?? 2,
            intervalMs: options["intervalMs"] as? Int ?? 2000,
            needAddress: options["needAddress"] as? Bool ?? true
        )
    }
}
