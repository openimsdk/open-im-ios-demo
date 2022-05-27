
import Foundation
import JNFoundation

class DemoPlugin: Plugin.Name {
    static let shared: DemoPlugin = DemoPlugin()
    private var baseUrl: String = ""
    func setup(baseUrl: String) {
        self.baseUrl = baseUrl
        do {
            try Plugin.register(pluginName: self)
        } catch let err as Plugin.PluginError {
            print(err)
        } catch {
            print(error)
        }
        let mainNet: Net = Net.init(plugin: self.getPlugin(), baseUrl: self.baseUrl).setToMainNet().setHttpBuilder(StubHttpBuilder())
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
        guard let net = getPlugin().getNet(byBaseUrl: self.baseUrl) else {
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
