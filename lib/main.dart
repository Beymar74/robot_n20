import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

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

// ============================================================
//  PÁGINA PRINCIPAL - Conexión Bluetooth
// ============================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<BluetoothDevice> dispositivos = [];
  bool buscando = false;

  @override
  void initState() {
    super.initState();
    buscarDispositivos();
  }

  Future<void> buscarDispositivos() async {
    setState(() => buscando = true);
    try {
      List<BluetoothDevice> lista =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        dispositivos = lista;
        buscando = false;
      });
    } catch (e) {
      setState(() => buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B5BA5),
        title: const Text('Robot N20 - Bluetooth',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: buscarDispositivos,
          )
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF16213E),
            child: Column(
              children: [
                const Icon(Icons.bluetooth, color: Color(0xFF4FC3F7), size: 48),
                const SizedBox(height: 8),
                const Text('Selecciona tu ESP32',
                    style: TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Text('Busca "Robot_N20" en la lista',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          // Lista de dispositivos
          Expanded(
            child: buscando
                ? const Center(child: CircularProgressIndicator())
                : dispositivos.isEmpty
                    ? const Center(
                        child: Text('No hay dispositivos emparejados.\nEmpareja el ESP32 primero en Ajustes > Bluetooth',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: dispositivos.length,
                        itemBuilder: (context, i) {
                          final d = dispositivos[i];
                          return Card(
                            color: const Color(0xFF16213E),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.bluetooth,
                                  color: Color(0xFF4FC3F7)),
                              title: Text(d.name ?? 'Desconocido',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(d.address,
                                  style: const TextStyle(color: Colors.white54)),
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  color: Colors.white38, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ControlPage(device: d),
                                  ),
                                );
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

// ============================================================
//  PÁGINA DE CONTROL
// ============================================================
class ControlPage extends StatefulWidget {
  final BluetoothDevice device;
  const ControlPage({super.key, required this.device});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  BluetoothConnection? conexion;
  bool conectado = false;
  bool conectando = false;
  String ultimoLog = 'Desconectado';

  final TextEditingController _distanciaCtrl = TextEditingController();
  final TextEditingController _gradosCtrl = TextEditingController();
  final TextEditingController _velCtrl = TextEditingController(text: '150');

  @override
  void initState() {
    super.initState();
    conectar();
  }

  Future<void> conectar() async {
    setState(() => conectando = true);
    try {
      BluetoothConnection conn =
          await BluetoothConnection.toAddress(widget.device.address);
      setState(() {
        conexion = conn;
        conectado = true;
        conectando = false;
        ultimoLog = 'Conectado a ${widget.device.name}';
      });
      // Escuchar respuestas del ESP32
      conn.input!.listen((data) {
        String msg = utf8.decode(data).trim();
        if (msg.isNotEmpty) {
          setState(() => ultimoLog = msg);
        }
      });
    } catch (e) {
      setState(() {
        conectando = false;
        ultimoLog = 'Error al conectar: $e';
      });
    }
  }

  void enviar(String cmd) {
    if (conexion != null && conectado) {
      conexion!.output.add(utf8.encode('$cmd\n'));
      setState(() => ultimoLog = 'Enviado: $cmd');
    }
  }

  @override
  void dispose() {
    conexion?.dispose();
    super.dispose();
  }

  // ---- WIDGETS ----

  Widget _botonAccion(String label, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: onTap != null ? color : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _seccion(String titulo, Widget contenido) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(titulo,
                style: const TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: contenido,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B5BA5),
        title: Text(widget.device.name ?? 'Robot',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              conectado ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: conectado ? Colors.greenAccent : Colors.redAccent,
            ),
          )
        ],
      ),
      body: conectando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Conectando...', style: TextStyle(color: Colors.white)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // Log
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF3B5BA5)),
                    ),
                    child: Text('📟  $ultimoLog',
                        style: const TextStyle(
                            color: Colors.greenAccent, fontSize: 13,
                            fontFamily: 'monospace')),
                  ),
                  const SizedBox(height: 12),

                  // Controles rápidos
                  _seccion('Control Rápido',
                    Column(
                      children: [
                        // Adelante
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _botonAccion('Adelante', Icons.arrow_upward,
                                const Color(0xFF2ECC71),
                                conectado ? () => enviar('A') : null),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Izquierda / Stop / Derecha
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _botonAccion('Izq', Icons.rotate_left,
                                const Color(0xFF3B5BA5),
                                conectado ? () => enviar('G-90') : null),
                            const SizedBox(width: 10),
                            _botonAccion('STOP', Icons.stop,
                                const Color(0xFFE74C3C),
                                conectado ? () => enviar('S') : null),
                            const SizedBox(width: 10),
                            _botonAccion('Der', Icons.rotate_right,
                                const Color(0xFF3B5BA5),
                                conectado ? () => enviar('G90') : null),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Atrás
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _botonAccion('Atrás', Icons.arrow_downward,
                                const Color(0xFFE67E22),
                                conectado ? () => enviar('R') : null),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Distancia específica
                  _seccion('Avanzar Distancia (cm)',
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _distanciaCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Ej: 20 o -15',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF0D1117),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.straighten,
                                  color: Color(0xFF4FC3F7)),
                              suffixText: 'cm',
                              suffixStyle: const TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2ECC71),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: conectado
                              ? () {
                                  final val = _distanciaCtrl.text.trim();
                                  if (val.isNotEmpty) enviar('D$val');
                                }
                              : null,
                          child: const Text('IR',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  // Giro específico
                  _seccion('Girar Grados (°)',
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _gradosCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Ej: 90 o -45',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF0D1117),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.rotate_right,
                                  color: Color(0xFF4FC3F7)),
                              suffixText: '°',
                              suffixStyle: const TextStyle(color: Colors.white54),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B5BA5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: conectado
                              ? () {
                                  final val = _gradosCtrl.text.trim();
                                  if (val.isNotEmpty) enviar('G$val');
                                }
                              : null,
                          child: const Text('GIRAR',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  // Velocidad
                  _seccion('Velocidad PWM (0-255)',
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _velCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: '0 - 255',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF0D1117),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              prefixIcon: const Icon(Icons.speed,
                                  color: Color(0xFF4FC3F7)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE67E22),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: conectado
                              ? () {
                                  final val = _velCtrl.text.trim();
                                  if (val.isNotEmpty) enviar('VEL:$val');
                                }
                              : null,
                          child: const Text('SET',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  // Giros rápidos
                  _seccion('Giros Rápidos',
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _botonAccion('45°', Icons.rotate_right,
                            const Color(0xFF6B85C4),
                            conectado ? () => enviar('G45') : null),
                        _botonAccion('90°', Icons.rotate_right,
                            const Color(0xFF3B5BA5),
                            conectado ? () => enviar('G90') : null),
                        _botonAccion('180°', Icons.rotate_right,
                            const Color(0xFF2C3E8C),
                            conectado ? () => enviar('G180') : null),
                        _botonAccion('-90°', Icons.rotate_left,
                            const Color(0xFF3B5BA5),
                            conectado ? () => enviar('G-90') : null),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}