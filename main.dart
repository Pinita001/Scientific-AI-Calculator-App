import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart' as math;
import 'dart:math' show pi, e;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';

// Hardcode your key here (only used for AI Assist tab)
const String kOpenAIKey = 'sk-proj-8FeyBfMxSxr7Rxno_JoDqNyYTiMeTLgpk7RJD4gL8mGrwApNMv8CdY5wi06HXadc8hdCRK6x3RT3BlbkFJ_9wX_SasPEKJ5jfGEUG5KBFILtQwtRLfG5vFa_0Y9jaR5Vo4CHdb4Q8vBnbH5itSw-dqQ_mT0AE';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeTabs(),
    );
  }
}

class HomeTabs extends StatefulWidget {
  const HomeTabs({super.key});
  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  int _index = 0;
  final List<Widget> _screens = const [RealCalculatorPage(), AIAssistPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFEDE9FE),
        selectedItemColor: const Color(0xFF7C3AED),
        unselectedItemColor: Colors.black54,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calculate_rounded), label: "Real"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "AI Assist"),
        ],
      ),
    );
  }
}

/// ---------------- REAL CALCULATOR ----------------
class RealCalculatorPage extends StatefulWidget {
  const RealCalculatorPage({super.key});
  @override
  State<RealCalculatorPage> createState() => _RealCalculatorPageState();
}

class _RealCalculatorPageState extends State<RealCalculatorPage> {
  String _expression = '';
  String _result = '';
  bool _isRadian = true;

  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _listening = false;

  String _normalize(String s) {
    s = s.trim();
    s = s.replaceAll('π', 'pi').replaceAll('phi', '1.618');
    s = s.replaceAll(RegExp(r'\bpoint\b', caseSensitive: false), '.');
    s = s.replaceAll(RegExp(r'\bsine\b', caseSensitive: false), 'sin');
    s = s.replaceAll(RegExp(r'\bcosine\b', caseSensitive: false), 'cos');
    s = s.replaceAll(RegExp(r'\btangent\b', caseSensitive: false), 'tan');

    // Automatically add parentheses if missing for trig functions
    s = s.replaceAllMapped(
      RegExp(r'\b(sin|cos|tan|asin|acos|atan)\s*([-+]?\d+(?:\.\d+)?)\b'),
      (m) => '${m[1]}(${m[2]})',
    );
    return s;
  }

  String _degConvert(String expr) {
    if (_isRadian) return expr;
    for (final f in ['sin', 'cos', 'tan', 'asin', 'acos', 'atan']) {
      expr = expr.replaceAllMapped(RegExp('$f\\(([^)]+)\\)'), (m) {
        final inside = m[1]!;
        if (f.startsWith('a')) return '${m[0]}';
        return '$f((pi/180)*$inside)';
      });
    }
    return expr;
  }

  void _append(String s) {
    setState(() {
      _expression += s;
      _controller.text = _expression;
    });
  }

  void _clear() => setState(() {
        _expression = '';
        _result = '';
        _controller.clear();
      });

  void _backspace() {
    if (_expression.isNotEmpty) {
      setState(() {
        _expression = _expression.substring(0, _expression.length - 1);
        _controller.text = _expression;
      });
    }
  }

  void _evaluate() {
    try {
      var expr = _normalize(_expression);
      expr = _degConvert(expr);

      final parser = math.Parser();
      final exp = parser.parse(expr);
      final cm = math.ContextModel()
        ..bindVariableName('pi', math.Number(pi))
        ..bindVariableName('e', math.Number(e));
      var val = exp.evaluate(math.EvaluationType.REAL, cm);

      if (!_isRadian && _usesInverse(expr)) val = val * 180 / pi;
      setState(() => _result = _formatNumber(val));
    } catch (_) {
      setState(() => _result = 'Invalid input');
    }
  }

  bool _usesInverse(String expr) =>
      expr.contains('asin(') || expr.contains('acos(') || expr.contains('atan(');

  String _formatNumber(num v) {
    final s = v.toString();
    if (s.contains('.') && s.length > 12) return v.toStringAsFixed(8);
    return s;
  }

  Future<void> _listen() async {
    if (!_listening) {
      final ok = await _stt.initialize();
      if (ok) {
        setState(() => _listening = true);
        _stt.listen(onResult: (r) {
          if (r.finalResult) {
            setState(() {
              _expression = r.recognizedWords;
              _controller.text = _expression;
              _listening = false;
            });
          }
        });
      }
    } else {
      _stt.stop();
      setState(() => _listening = false);
    }
  }

  void _openConstants() {
    final constants = <String, String>{
      'π': 'pi',
      'e': 'e',
      'φ': '1.618',
      'c (m/s)': '3e8',
      'g (m/s²)': '9.81',
      'NA': '6.022e23',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFEE2E2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: constants.entries
              .map((e) => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBCFE8),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _append(e.value);
                      Navigator.pop(context);
                    },
                    child: Text(e.key,
                        style: const TextStyle(color: Colors.white)),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _openAdv() {
    final adv = [
      'sin(', 'cos(', 'tan(', 'asin(', 'acos(', 'atan(',
      'log(', 'ln(', 'sqrt(', 'exp(', '^',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF3E8FF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Advanced",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Row(children: [
                const Text("Trig: "),
                ChoiceChip(
                  label: const Text('Rad'),
                  selected: _isRadian,
                  onSelected: (_) => setState(() => _isRadian = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Deg'),
                  selected: !_isRadian,
                  onSelected: (_) => setState(() => _isRadian = false),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: adv
                .map((a) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6BCFA),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        _append(a);
                        Navigator.pop(context);
                      },
                      child: Text(a,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                    ))
                .toList(),
          ),
        ]),
      ),
    );
  }

  Widget _key(String t, {Color? c, VoidCallback? onTap}) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: c ?? const Color(0xFFD6BCFA),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onTap ?? () => _append(t),
            child: Text(t,
                style: const TextStyle(fontSize: 20, color: Colors.white)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final modeLabel = _isRadian ? 'RAD' : 'DEG';

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDE9FE),
        title: Text('Real Calculator — $modeLabel',
            style: const TextStyle(color: Colors.black87)),
        actions: [
          IconButton(
              onPressed: _openConstants,
              icon: const Icon(Icons.menu_book_rounded, color: Colors.black)),
          IconButton(
              onPressed: _listen,
              icon: Icon(_listening ? Icons.mic_off : Icons.mic,
                  color: Colors.black)),
        ],
      ),
      body: Column(children: [
        // Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          color: const Color(0xFFF3E8FF),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_expression,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 28, color: Colors.black54)),
              const SizedBox(height: 8),
              Text(_result,
                  style: const TextStyle(
                      fontSize: 36,
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        // Keypad
        Expanded(
          child: Container(
            color: const Color(0xFFFDFBFF),
            child: Column(
              children: [
                Row(children: [
                  _key('ADV', c: const Color(0xFFF9A8D4), onTap: _openAdv),
                  _key('C', c: const Color(0xFFFCA5A5), onTap: _clear),
                  _key('⌫', c: const Color(0xFFFB7185), onTap: _backspace),
                  _key('/', c: const Color(0xFFA78BFA)),
                ]),
                Row(children: [
                  _key('7'),
                  _key('8'),
                  _key('9'),
                  _key('*', c: const Color(0xFFA78BFA)),
                ]),
                Row(children: [
                  _key('4'),
                  _key('5'),
                  _key('6'),
                  _key('-', c: const Color(0xFFA78BFA)),
                ]),
                Row(children: [
                  _key('1'),
                  _key('2'),
                  _key('3'),
                  _key('+', c: const Color(0xFFA78BFA)),
                ]),
                Row(children: [
                  _key('0'),
                  _key('.'),
                  _key('(', c: const Color(0xFFBAE6FD)),
                  _key(')', c: const Color(0xFFBAE6FD)),
                  _key('=', c: const Color(0xFF9F7AEA), onTap: _evaluate),
                ]),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

/// ---------------- AI ASSIST ----------------
class AIAssistPage extends StatefulWidget {
  const AIAssistPage({super.key});
  @override
  State<AIAssistPage> createState() => _AIAssistPageState();
}

class _AIAssistPageState extends State<AIAssistPage> {
  final _controller = TextEditingController();
  String _response = '';

  Future<void> _ask(String query) async {
    if (kOpenAIKey.isEmpty || kOpenAIKey.startsWith('sk-REPLACE')) {
      setState(() => _response = 'Missing API key');
      return;
    }
    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $kOpenAIKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': 'You are a helpful math tutor.'},
            {'role': 'user', 'content': query},
          ],
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _response = data['choices'][0]['message']['content']);
      } else {
        setState(() => _response = 'ChatGPT error ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _response = 'Network error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEDE9FE),
        title: const Text('AI Assist', style: TextStyle(color: Colors.black87)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: "Ask a math question or word problem...",
              filled: true,
              fillColor: const Color(0xFFF3E8FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _ask(_controller.text),
              ),
            ),
            onSubmitted: (_) => _ask(_controller.text),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                _response,
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
