
import Foundation
import JNFoundation

class DemoPlugin: Plugin.Name {
    static let shared: DemoPlugin = DemoPlugin()
    private(set) var BaseUrl = "http://121.37.25.71:10004/"
    func setup(baseUrl: String) {
        do {
            try Plugin.register(pluginName: self)
            BaseUrl = baseUrl;
        } catch let err as Plugin.PluginError {
            print(err)
        } catch {
            print(error)
        }
        let mainNet: Net = Net.init(plugin: self.getPlugin(), baseUrl: self.BaseUrl).setToMainNet().setHttpBuilder(StubHttpBuilder())
        self.getPlugin().setMainNet(mainNet)
        print("homeDir=\(NSHomeDirectory())")
    }

    func getPlugin() -> Plugin {
        guard let plugin = Plugin.getBy(name: self) else {
            fatalError("call \(self).setup first!")
        }
        return plugin
    }

    func getMainNet() -> Net {
        guard let net = getPlugin().getNet(byBaseUrl: self.BaseUrl) else {
            fatalError("初始化net时，调用一下setToMainNet")
        }
        return net
    }

    func getMf() -> ModelFactory {
        return getPlugin().getMf()
    }

    func getNc() -> JNNotificationCenter {
        return getPlugin().getNc()
    }
}
