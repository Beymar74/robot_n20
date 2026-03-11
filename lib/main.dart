import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

const String SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
const String CHAR_TX_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
const String CHAR_RX_UUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";

// ── Paleta ──────────────────────────────────────────────────
const cBg      = Color(0xFF0A0E1A);
const cSurface = Color(0xFF111827);
const cCard    = Color(0xFF1A2235);
const cBorder  = Color(0xFF1F2D45);
const cCyan    = Color(0xFF00E5FF);
const cGreen   = Color(0xFF00FF9C);
const cOrange  = Color(0xFFFF6B35);
const cRed     = Color(0xFFFF3366);
const cBlue    = Color(0xFF3B82F6);
const cText    = Color(0xFFE2E8F0);
const cMuted   = Color(0xFF64748B);

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: cBg,
        fontFamily: 'monospace',
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HOME PAGE
// ══════════════════════════════════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  List<ScanResult> resultados = [];
  bool buscando = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    escanear();
  }

  @override
  void dispose() { _pulseCtrl.dispose(); super.dispose(); }

  Future<void> escanear() async {
    setState(() { buscando = true; resultados = []; });
    FlutterBluePlus.scanResults.listen((r) => setState(() => resultados = r));
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    setState(() => buscando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: Column(children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(children: [
              // Logo
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  border: Border.all(color: cCyan, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.precision_manufacturing, color: cCyan, size: 22),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('ROBOT N20',
                    style: TextStyle(color: cText, fontSize: 18,
                        fontWeight: FontWeight.w800, letterSpacing: 3)),
                Text('CONTROL SYSTEM v1.0',
                    style: TextStyle(color: cMuted, fontSize: 10, letterSpacing: 2)),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: buscando ? null : escanear,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: cBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => Icon(Icons.radar,
                        color: buscando ? cCyan.withOpacity(_pulse.value) : cMuted,
                        size: 20),
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 32),

          // ── Indicador central ──
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: buscando
                        ? cCyan.withOpacity(_pulse.value)
                        : cBorder,
                    width: 2),
                boxShadow: buscando ? [
                  BoxShadow(color: cCyan.withOpacity(_pulse.value * 0.3),
                      blurRadius: 30, spreadRadius: 5)
                ] : [],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.bluetooth_searching,
                    color: buscando ? cCyan : cMuted, size: 36),
                const SizedBox(height: 6),
                Text(buscando ? 'SCAN...' : 'READY',
                    style: TextStyle(
                        color: buscando ? cCyan : cMuted,
                        fontSize: 11, letterSpacing: 2,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            buscando ? 'Escaneando dispositivos BLE...' : '${resultados.length} dispositivos encontrados',
            style: const TextStyle(color: cMuted, fontSize: 12, letterSpacing: 1),
          ),

          const SizedBox(height: 24),

          // ── Lista ──
          Expanded(
            child: resultados.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.device_unknown, color: cMuted.withOpacity(0.4), size: 48),
                      const SizedBox(height: 12),
                      const Text('Sin dispositivos', style: TextStyle(color: cMuted)),
                      const SizedBox(height: 4),
                      const Text('Enciende el ESP32 e intenta de nuevo',
                          style: TextStyle(color: cMuted, fontSize: 12)),
                    ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: resultados.length,
                    itemBuilder: (ctx, i) {
                      final r = resultados[i];
                      final nombre = r.device.platformName.isNotEmpty
                          ? r.device.platformName : 'Desconocido';
                      final esRobot = nombre == 'Robot_N20';
                      return _DeviceCard(
                        nombre: nombre,
                        mac: r.device.remoteId.str,
                        rssi: r.rssi,
                        esRobot: esRobot,
                        onTap: () {
                          FlutterBluePlus.stopScan();
                          Navigator.push(ctx, MaterialPageRoute(
                            builder: (_) => ControlPage(device: r.device)));
                        },
                      );
                    }),
          ),
        ]),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String nombre, mac;
  final int rssi;
  final bool esRobot;
  final VoidCallback onTap;
  const _DeviceCard({required this.nombre, required this.mac,
      required this.rssi, required this.esRobot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = esRobot ? cGreen : cMuted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: esRobot ? cGreen.withOpacity(0.4) : cBorder),
          boxShadow: esRobot ? [
            BoxShadow(color: cGreen.withOpacity(0.1), blurRadius: 20)
          ] : [],
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(Icons.memory, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nombre, style: TextStyle(color: esRobot ? cGreen : cText,
                fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 2),
            Text(mac, style: const TextStyle(color: cMuted, fontSize: 11)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$rssi dBm', style: const TextStyle(color: cMuted, fontSize: 11)),
            const SizedBox(height: 4),
            if (esRobot) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cGreen.withOpacity(0.4)),
              ),
              child: const Text('ESP32', style: TextStyle(color: cGreen,
                  fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  CONTROL PAGE
// ══════════════════════════════════════════════════════════════
class ControlPage extends StatefulWidget {
  final BluetoothDevice device;
  const ControlPage({super.key, required this.device});
  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> with TickerProviderStateMixin {
  bool conectado = false, conectando = false;
  String ultimoLog = 'Iniciando conexión...';
  BluetoothCharacteristic? rxChar, txChar;
  List<String> historial = [];

  final _distCtrl = TextEditingController();
  final _gradCtrl = TextEditingController();
  final _velCtrl  = TextEditingController(text: '150');
  double _velSlider = 150;

  late AnimationController _connectAnim;
  late Animation<double> _connectPulse;

  @override
  void initState() {
    super.initState();
    _connectAnim = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _connectPulse = Tween(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _connectAnim, curve: Curves.easeInOut));
    conectar();
  }

  @override
  void dispose() {
    _connectAnim.dispose();
    widget.device.disconnect();
    super.dispose();
  }

  Future<void> conectar() async {
    setState(() => conectando = true);
    try {
      await widget.device.connect(timeout: const Duration(seconds: 10));
      final services = await widget.device.discoverServices();
      for (var s in services) {
        if (s.uuid.toString().toLowerCase() == SERVICE_UUID) {
          for (var c in s.characteristics) {
            final uuid = c.uuid.toString().toLowerCase();
            if (uuid == CHAR_RX_UUID) rxChar = c;
            if (uuid == CHAR_TX_UUID) txChar = c;
          }
        }
      }
      if (txChar != null) {
        await txChar!.setNotifyValue(true);
        txChar!.onValueReceived.listen((data) {
          final msg = utf8.decode(data).trim();
          if (msg.isNotEmpty) setState(() {
            ultimoLog = msg;
            historial.insert(0, msg);
            if (historial.length > 10) historial.removeLast();
          });
        });
      }
      setState(() { conectado = true; conectando = false;
        ultimoLog = 'Conectado ✓'; });
      _connectAnim.stop();
    } catch (e) {
      setState(() { conectando = false; ultimoLog = 'Error: $e'; });
    }
  }

  void enviar(String cmd) {
    if (rxChar != null && conectado) {
      HapticFeedback.lightImpact();
      rxChar!.write(utf8.encode('$cmd\n'), withoutResponse: true);
      setState(() {
        ultimoLog = '▶ $cmd';
        historial.insert(0, '▶ $cmd');
        if (historial.length > 10) historial.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          _buildStatusBar(),
          Expanded(
            child: conectando ? _buildConnecting() : _buildControls(),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: cBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: cText, size: 16),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.device.platformName.isNotEmpty
              ? widget.device.platformName : 'Robot',
              style: const TextStyle(color: cText, fontSize: 17,
                  fontWeight: FontWeight.bold, letterSpacing: 1)),
          Text(widget.device.remoteId.str,
              style: const TextStyle(color: cMuted, fontSize: 11)),
        ])),
        // Estado conexión
        AnimatedBuilder(
          animation: _connectPulse,
          builder: (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (conectado ? cGreen : cOrange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: (conectado ? cGreen : cOrange).withOpacity(
                      conectado ? 1.0 : _connectPulse.value)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(
                      color: conectado ? cGreen : cOrange,
                      shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(conectado ? 'ONLINE' : 'LINK...',
                  style: TextStyle(
                      color: conectado ? cGreen : cOrange,
                      fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cBorder),
      ),
      child: Row(children: [
        const Icon(Icons.terminal, color: cCyan, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(ultimoLog,
            style: const TextStyle(color: cCyan, fontSize: 12, letterSpacing: 0.5),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _buildConnecting() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AnimatedBuilder(
        animation: _connectPulse,
        builder: (_, __) => Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cCyan.withOpacity(_connectPulse.value), width: 2),
            boxShadow: [BoxShadow(color: cCyan.withOpacity(_connectPulse.value * 0.3),
                blurRadius: 20)],
          ),
          child: const Icon(Icons.bluetooth_searching, color: cCyan, size: 36),
        ),
      ),
      const SizedBox(height: 20),
      const Text('ESTABLECIENDO CONEXIÓN', style: TextStyle(color: cCyan,
          letterSpacing: 2, fontSize: 13, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      const Text('BLE NUS Protocol', style: TextStyle(color: cMuted, fontSize: 12)),
    ]));
  }

  Widget _buildControls() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [

        // ── D-PAD ──────────────────────────────────────────
        _NeonCard(
          label: 'MOVIMIENTO',
          child: Column(children: [
            // Adelante
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _DpadButton(icon: Icons.keyboard_arrow_up, label: 'FWD',
                  color: cGreen, onTap: conectado ? () => enviar('A') : null),
            ]),
            const SizedBox(height: 8),
            // Izq / Stop / Der
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _DpadButton(icon: Icons.keyboard_arrow_left, label: 'L-90',
                  color: cBlue, onTap: conectado ? () => enviar('G-90') : null),
              const SizedBox(width: 8),
              _DpadButton(icon: Icons.stop_rounded, label: 'STOP',
                  color: cRed, size: 64, onTap: conectado ? () => enviar('S') : null),
              const SizedBox(width: 8),
              _DpadButton(icon: Icons.keyboard_arrow_right, label: 'R-90',
                  color: cBlue, onTap: conectado ? () => enviar('G90') : null),
            ]),
            const SizedBox(height: 8),
            // Atrás
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _DpadButton(icon: Icons.keyboard_arrow_down, label: 'REV',
                  color: cOrange, onTap: conectado ? () => enviar('R') : null),
            ]),
          ]),
        ),

        const SizedBox(height: 12),

        // ── DISTANCIA + GRADOS ──────────────────────────────
        Row(children: [
          Expanded(child: _NeonCard(
            label: 'DISTANCIA',
            child: Column(children: [
              _InputField(ctrl: _distCtrl, hint: '20', sufijo: 'cm',
                  icon: Icons.straighten),
              const SizedBox(height: 10),
              _ActionButton(label: 'MOVER', color: cGreen,
                  onTap: conectado ? () {
                    final v = _distCtrl.text.trim();
                    if (v.isNotEmpty) enviar('D$v');
                  } : null),
            ]),
          )),
          const SizedBox(width: 10),
          Expanded(child: _NeonCard(
            label: 'GIRO',
            child: Column(children: [
              _InputField(ctrl: _gradCtrl, hint: '90', sufijo: '°',
                  icon: Icons.rotate_right),
              const SizedBox(height: 10),
              _ActionButton(label: 'GIRAR', color: cBlue,
                  onTap: conectado ? () {
                    final v = _gradCtrl.text.trim();
                    if (v.isNotEmpty) enviar('G$v');
                  } : null),
            ]),
          )),
        ]),

        const SizedBox(height: 12),

        // ── GIROS RÁPIDOS ───────────────────────────────────
        _NeonCard(
          label: 'GIROS RÁPIDOS',
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
            _QuickBtn(label: '-180', onTap: conectado ? () => enviar('G-180') : null),
            _QuickBtn(label: '-90',  onTap: conectado ? () => enviar('G-90')  : null),
            _QuickBtn(label: '-45',  onTap: conectado ? () => enviar('G-45')  : null),
            _QuickBtn(label: '+45',  onTap: conectado ? () => enviar('G45')   : null),
            _QuickBtn(label: '+90',  onTap: conectado ? () => enviar('G90')   : null),
            _QuickBtn(label: '+180', onTap: conectado ? () => enviar('G180')  : null),
          ]),
        ),

        const SizedBox(height: 12),

        // ── VELOCIDAD ───────────────────────────────────────
        _NeonCard(
          label: 'VELOCIDAD  PWM: ${_velSlider.toInt()}',
          child: Column(children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: cCyan,
                inactiveTrackColor: cBorder,
                thumbColor: cCyan,
                overlayColor: cCyan.withOpacity(0.1),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: _velSlider,
                min: 80, max: 255,
                onChanged: (v) => setState(() {
                  _velSlider = v;
                  _velCtrl.text = v.toInt().toString();
                }),
                onChangeEnd: (v) => enviar('VEL:${v.toInt()}'),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('80', style: TextStyle(color: cMuted, fontSize: 11)),
              Text('${_velSlider.toInt()}',
                  style: const TextStyle(color: cCyan, fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const Text('255', style: TextStyle(color: cMuted, fontSize: 11)),
            ]),
          ]),
        ),

        const SizedBox(height: 12),

        // ── LOG ─────────────────────────────────────────────
        if (historial.isNotEmpty)
          _NeonCard(
            label: 'HISTORIAL',
            child: Column(
              children: historial.take(5).map((msg) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  const Text('›', style: TextStyle(color: cCyan, fontSize: 12)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(msg,
                      style: const TextStyle(color: cText, fontSize: 11),
                      overflow: TextOverflow.ellipsis)),
                ]),
              )).toList(),
            ),
          ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  WIDGETS REUTILIZABLES
// ══════════════════════════════════════════════════════════════

class _NeonCard extends StatelessWidget {
  final String label;
  final Widget child;
  const _NeonCard({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 3, height: 12,
              decoration: BoxDecoration(color: cCyan,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: cCyan, fontSize: 11,
              fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class _DpadButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double size;
  final VoidCallback? onTap;
  const _DpadButton({required this.icon, required this.label,
      required this.color, this.size = 56, this.onTap});
  @override
  State<_DpadButton> createState() => _DpadButtonState();
}

class _DpadButtonState extends State<_DpadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.size, height: widget.size,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withOpacity(0.3)
              : widget.color.withOpacity(widget.onTap != null ? 0.1 : 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: widget.color.withOpacity(widget.onTap != null ? 0.6 : 0.2),
              width: _pressed ? 2 : 1.5),
          boxShadow: _pressed ? [
            BoxShadow(color: widget.color.withOpacity(0.3), blurRadius: 12)
          ] : [],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(widget.icon,
              color: widget.color.withOpacity(widget.onTap != null ? 1.0 : 0.3),
              size: widget.size * 0.42),
          Text(widget.label,
              style: TextStyle(
                  color: widget.color.withOpacity(widget.onTap != null ? 0.8 : 0.3),
                  fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ]),
      ),
    );
  }
}

class _QuickBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _QuickBtn({required this.label, this.onTap});
  @override
  State<_QuickBtn> createState() => _QuickBtnState();
}

class _QuickBtnState extends State<_QuickBtn> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _pressed ? cBlue.withOpacity(0.25) : cBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cBlue.withOpacity(_pressed ? 0.8 : 0.3)),
        ),
        child: Text(widget.label,
            style: TextStyle(color: cBlue.withOpacity(widget.onTap != null ? 1.0 : 0.3),
                fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint, sufijo;
  final IconData icon;
  const _InputField({required this.ctrl, required this.hint,
      required this.sufijo, required this.icon});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
      style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: cMuted),
        filled: true, fillColor: cSurface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: cCyan, width: 1.5)),
        suffixText: sufijo,
        suffixStyle: const TextStyle(color: cCyan, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: cMuted, size: 18),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionButton({required this.label, required this.color, this.onTap});
  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: double.infinity, height: 42,
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withOpacity(0.3)
              : widget.color.withOpacity(widget.onTap != null ? 0.12 : 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: widget.color.withOpacity(widget.onTap != null ? 0.6 : 0.2)),
          boxShadow: _pressed ? [
            BoxShadow(color: widget.color.withOpacity(0.25), blurRadius: 10)
          ] : [],
        ),
        child: Center(
          child: Text(widget.label,
              style: TextStyle(
                  color: widget.color.withOpacity(widget.onTap != null ? 1.0 : 0.3),
                  fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ),
      ),
    );
  }
}