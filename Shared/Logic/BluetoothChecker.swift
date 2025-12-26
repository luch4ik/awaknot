import Foundation
import CoreBluetooth
import SwiftUI

// MARK: - Bluetooth Logic

class BluetoothChecker: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    static let shared = BluetoothChecker()

    private var centralManager: CBCentralManager!
    @Published var discoveredPeripherals: [(peripheral: CBPeripheral, name: String)] = []
    @Published var isScanning: Bool = false
    @Published var targetDeviceConnected: Bool = false
    @Published var bluetoothState: CBManagerState = .unknown

    private var targetPeripheral: CBPeripheral?
    private var targetDeviceName: String?
    private var scanTimeout: Timer?
    private var usePairedDevicesOnly: Bool = false
    var onDeviceConnected: (() -> Void)?

    // MARK: - Paired Devices Storage

    private let pairedDevicesKey = "ItsukiAlarmPairedDevices"

    var pairedDevices: [String] {
        get {
            UserDefaults.standard.stringArray(forKey: pairedDevicesKey) ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: pairedDevicesKey)
        }
    }

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - Paired Devices Management

    func addToPairedDevices(_ deviceName: String) {
        var devices = pairedDevices
        if !devices.contains(deviceName) {
            devices.append(deviceName)
            pairedDevices = devices
        }
    }

    func removeFromPairedDevices(_ deviceName: String) {
        pairedDevices = pairedDevices.filter { $0 != deviceName }
    }

    func isPaired(_ deviceName: String) -> Bool {
        return pairedDevices.contains(deviceName)
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.bluetoothState = central.state
        }

        if central.state == .poweredOn {
            print("Bluetooth is powered on and ready")
        } else {
            print("Bluetooth state: \(central.state.rawValue)")
            stopScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let deviceName = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown Device"

        // Filter by paired devices if enabled
        if usePairedDevicesOnly && !isPaired(deviceName) {
            return
        }

        // Avoid duplicates
        if !discoveredPeripherals.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
            DispatchQueue.main.async {
                self.discoveredPeripherals.append((peripheral, deviceName))
            }
        }

        // If this is our target device, attempt connection
        if let target = targetDeviceName, deviceName == target {
            print("Found target device: \(deviceName)")
            targetPeripheral = peripheral
            peripheral.delegate = self
            centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let deviceName = peripheral.name ?? "Unknown"
        print("Connected to peripheral: \(deviceName)")

        // Auto-add to paired devices on successful connection
        addToPairedDevices(deviceName)

        stopScanning()

        DispatchQueue.main.async {
            self.targetDeviceConnected = true
            self.onDeviceConnected?()
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral: \(error?.localizedDescription ?? "Unknown error")")

        DispatchQueue.main.async {
            self.targetDeviceConnected = false
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from peripheral: \(peripheral.name ?? "Unknown")")

        DispatchQueue.main.async {
            self.targetDeviceConnected = false
        }
    }

    // MARK: - Public Methods

    func startScanning(for deviceName: String? = nil, timeout: TimeInterval = 30.0, usePairedOnly: Bool = false) {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on")
            return
        }

        targetDeviceName = deviceName
        usePairedDevicesOnly = usePairedOnly
        discoveredPeripherals.removeAll()

        DispatchQueue.main.async {
            self.isScanning = true
        }

        // Scan for all peripherals (no service filter for maximum compatibility)
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])

        // Set timeout
        scanTimeout?.invalidate()
        scanTimeout = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            self?.stopScanning()
        }

        print("Started scanning for Bluetooth devices...")
    }

    func stopScanning() {
        centralManager.stopScan()
        scanTimeout?.invalidate()
        scanTimeout = nil

        DispatchQueue.main.async {
            self.isScanning = false
        }

        print("Stopped scanning for Bluetooth devices")
    }

    func cleanup() {
        stopScanning()

        if let peripheral = targetPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }

        targetPeripheral = nil
        targetDeviceName = nil
        onDeviceConnected = nil

        DispatchQueue.main.async {
            self.targetDeviceConnected = false
            self.discoveredPeripherals.removeAll()
        }
    }

    func isDeviceConnected(name: String) -> Bool {
        // Check if we have an active connection to a device with this name
        if let peripheral = targetPeripheral, peripheral.state == .connected {
            let deviceName = peripheral.name ?? "Unknown"
            return deviceName == name
        }
        return false
    }
}
