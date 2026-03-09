import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// UUID del ESP32 (NUS - Nordic UART Service)
const String SERVICE_UUID  = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
const String CHAR_TX_UUID  = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"; // ESP32 → App
const String CHAR_RX_UUID  = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"; // App → ESP32

void main() {
  runApp(const RobotApp());
}

class RobotApp extends StatelessWidget {
  const RobotApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot N20',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B5BA5),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ScanResult> resultados = [];
  bool buscando = false;

  @override
  void initState() {
    super.initState();
    escanear();
  }

  Future<void> escanear() async {
    setState(() { buscando = true; resultados = []; });
    FlutterBluePlus.scanResults.listen((results) {
      setState(() => resultados = results);
    });
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    setState(() => buscando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B5BA5),
        title: const Text('Robot N20 - BLE',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: buscando ? null : escanear,
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF16213E),
            child: Column(children: [
              Icon(buscando ? Icons.bluetooth_searching : Icons.bluetooth,
                  color: const Color(0xFF4FC3F7), size: 48),
              const SizedBox(height: 8),
              Text(buscando ? 'Buscando dispositivos...' : 'Selecciona tu ESP32',
                  style: const TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const Text('Busca "Robot_N20" en la lista',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            ]),
          ),
          Expanded(
            child: buscando && resultados.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : resultados.isEmpty
                    ? const Center(
                        child: Text('No se encontraron dispositivos.\nAsegúrate que el ESP32 está encendido.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: resultados.length,
                        itemBuilder: (context, i) {
                          final r = resultados[i];
                          final nombre = r.device.platformName.isNotEmpty
                              ? r.device.platformName : 'Desconocido';
                          final esRobot = nombre == 'Robot_N20';
                          return Card(
                            color: esRobot ? const Color(0xFF1B3A6B) : const Color(0xFF16213E),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(Icons.bluetooth,
                                  color: esRobot ? Colors.greenAccent : const Color(0xFF4FC3F7)),
                              title: Text(nombre,
                                  style: TextStyle(
                                      color: esRobot ? Colors.greenAccent : Colors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(r.device.remoteId.str,
                                  style: const TextStyle(color: Colors.white54)),
                              trailing: Text('${r.rssi} dBm',
                                  style: const TextStyle(color: Colors.white38)),
                              onTap: () {
                                FlutterBluePlus.stopScan();
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => ControlPage(device: r.device),
                                ));
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class ControlPage extends StatefulWidget {
  final BluetoothDevice device;
  const ControlPage({super.key, required this.device});
  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  bool conectado = false;
  bool conectando = false;
  String ultimoLog = 'Conectando...';
  BluetoothCharacteristic? rxChar;
  BluetoothCharacteristic? txChar;

  final _distanciaCtrl = TextEditingController();
  final _gradosCtrl    = TextEditingController();
  final _velCtrl       = TextEditingController(text: '150');

  @override
  void initState() { super.initState(); conectar(); }

  Future<void> conectar() async {
    setState(() => conectando = true);
    try {
      await widget.device.connect(timeout: const Duration(seconds: 10));
      List<BluetoothService> services = await widget.device.discoverServices();
      for (var s in services) {
        if (s.uuid.toString().toLowerCase() == SERVICE_UUID) {
          for (var c in s.characteristics) {
            String uuid = c.uuid.toString().toLowerCase();
            if (uuid == CHAR_RX_UUID) rxChar = c;
            if (uuid == CHAR_TX_UUID) txChar = c;
          }
        }
      }
      if (txChar != null) {
        await txChar!.setNotifyValue(true);
        txChar!.onValueReceived.listen((data) {
          String msg = utf8.decode(data).trim();
          if (msg.isNotEmpty) setState(() => ultimoLog = msg);
        });
      }
      setState(() { conectado = true; conectando = false;
        ultimoLog = 'Conectado a ${widget.device.platformName}'; });
    } catch (e) {
      setState(() { conectando = false; ultimoLog = 'Error: $e'; });
    }
  }

  void enviar(String cmd) {
    if (rxChar != null && conectado) {
      rxChar!.write(utf8.encode('$cmd\n'), withoutResponse: true);
      setState(() => ultimoLog = 'Enviado: $cmd');
    }
  }

  @override
  void dispose() { widget.device.disconnect(); super.dispose(); }

  Widget _boton(String label, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: onTap != null ? color : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12,
              fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _seccion(String titulo, Widget contenido) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(titulo, style: const TextStyle(color: Color(0xFF4FC3F7),
                fontWeight: FontWeight.bold, fontSize: 13))),
        Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: contenido),
      ]),
    );
  }

  Widget _campoEnviar(TextEditingController ctrl, String hint,
      IconData icon, String sufijo, Color btnColor, String btnLabel, String prefijo) {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(color: Colors.white38),
            filled: true, fillColor: const Color(0xFF0D1117),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            prefixIcon: Icon(icon, color: const Color(0xFF4FC3F7)),
            suffixText: sufijo, suffixStyle: const TextStyle(color: Colors.white54),
          ),
        ),
      ),
      const SizedBox(width: 10),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: conectado ? () {
          final val = ctrl.text.trim();
          if (val.isNotEmpty) enviar('$prefijo$val');
        } : null,
        child: Text(btnLabel, style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B5BA5),
        title: Text(widget.device.platformName.isNotEmpty
            ? widget.device.platformName : 'Robot',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [Padding(padding: const EdgeInsets.only(right: 12),
            child: Icon(conectado ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                color: conectado ? Colors.greenAccent : Colors.redAccent))],
      ),
      body: conectando
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [CircularProgressIndicator(), SizedBox(height: 16),
                Text('Conectando al robot...', style: TextStyle(color: Colors.white))]))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                // Log
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF3B5BA5))),
                  child: Text('📟  $ultimoLog', style: const TextStyle(
                      color: Colors.greenAccent, fontSize: 13, fontFamily: 'monospace')),
                ),
                const SizedBox(height: 12),

                // Direccional
                _seccion('Control Rápido', Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _boton('Adelante', Icons.arrow_upward, const Color(0xFF2ECC71),
                        conectado ? () => enviar('A') : null),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _boton('Izq', Icons.rotate_left, const Color(0xFF3B5BA5),
                        conectado ? () => enviar('G-90') : null),
                    const SizedBox(width: 10),
                    _boton('STOP', Icons.stop, const Color(0xFFE74C3C),
                        conectado ? () => enviar('S') : null),
                    const SizedBox(width: 10),
                    _boton('Der', Icons.rotate_right, const Color(0xFF3B5BA5),
                        conectado ? () => enviar('G90') : null),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _boton('Atrás', Icons.arrow_downward, const Color(0xFFE67E22),
                        conectado ? () => enviar('R') : null),
                  ]),
                ])),

                _seccion('Avanzar Distancia',
                  _campoEnviar(_distanciaCtrl, 'Ej: 20 o -15',
                      Icons.straighten, 'cm', const Color(0xFF2ECC71), 'IR', 'D')),

                _seccion('Girar Grados',
                  _campoEnviar(_gradosCtrl, 'Ej: 90 o -45',
                      Icons.rotate_right, '°', const Color(0xFF3B5BA5), 'GIRAR', 'G')),

                _seccion('Velocidad PWM (0-255)',
                  _campoEnviar(_velCtrl, '0 - 255',
                      Icons.speed, '', const Color(0xFFE67E22), 'SET', 'VEL:')),

                _seccion('Giros Rápidos', Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _boton('45°',  Icons.rotate_right, const Color(0xFF6B85C4),
                        conectado ? () => enviar('G45')  : null),
                    _boton('90°',  Icons.rotate_right, const Color(0xFF3B5BA5),
                        conectado ? () => enviar('G90')  : null),
                    _boton('180°', Icons.rotate_right, const Color(0xFF2C3E8C),
                        conectado ? () => enviar('G180') : null),
                    _boton('-90°', Icons.rotate_left,  const Color(0xFF3B5BA5),
                        conectado ? () => enviar('G-90') : null),
                  ],
                )),
              ]),
            ),
    );
  }
}