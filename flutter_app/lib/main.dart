import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http; // Make sure you ran: flutter pub add http

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proactive Scaler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005FB8),
          primary: const Color(0xFF107C10),
          onPrimary: const Color(0xFFFFFFFF),
          onSecondary: const Color(0xFFFFFFFF),
          secondary: const Color(0xFF475E75),
          tertiary: const Color(0xFFA04401),
          surface: const Color(0xFFFFFFFF),
          onSurfaceVariant: const Color.fromARGB(255, 78, 80, 83),
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Color(0xFF000000),
          ),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF000000)),
        ),
      ),
      home: const MyHomePage(title: 'Proactive Scaler'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to capture user input
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _activeUsersController = TextEditingController();
  final TextEditingController _bandwidthController = TextEditingController();
  final TextEditingController _memoryController = TextEditingController();
  final TextEditingController _execTimeController = TextEditingController();
  final TextEditingController _throughputController = TextEditingController();
  final TextEditingController _waitingTimeController = TextEditingController();
  final TextEditingController _errorRateController = TextEditingController();

  // State for Dropdowns / Segmented controls
  String _selectedJobPriority = 'Medium';
  String _selectedSchedulerType = 'ASB-Dynamic-CapsNet';
  String _selectedAllocationType = 'Dynamic';

  // State for API response
  bool _isLoading = false;
  String? _predictedCpu;
  String? _actionText;

  final _floatFormatter = FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'));

  @override
  void dispose() {
    _startTimeController.dispose();
    _activeUsersController.dispose();
    _bandwidthController.dispose();
    _memoryController.dispose();
    _execTimeController.dispose();
    _throughputController.dispose();
    _waitingTimeController.dispose();
    _errorRateController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        final String formattedDate =
            "${combinedDateTime.year.toString().padLeft(4, '0')}-"
            "${combinedDateTime.month.toString().padLeft(2, '0')}-"
            "${combinedDateTime.day.toString().padLeft(2, '0')} "
            "${combinedDateTime.hour.toString().padLeft(2, '0')}:"
            "${combinedDateTime.minute.toString().padLeft(2, '0')}:00";

        setState(() {
          _startTimeController.text = formattedDate;
        });
      }
    }
  }

  // --- API CALL LOGIC ---
  Future<void> _submitPrediction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _predictedCpu = null;
      _actionText = null;
    });

    try {
      final payload = {
        "Task_Start_Time": _startTimeController.text,
        "Number_of_Active_Users": int.parse(_activeUsersController.text),
        "Network_Bandwidth_Utilization": double.parse(_bandwidthController.text),
        "Memory_Consumption": double.parse(_memoryController.text),
        "Task_Execution_Time": double.parse(_execTimeController.text),
        "System_Throughput": double.parse(_throughputController.text),
        "Task_Waiting_Time": double.parse(_waitingTimeController.text),
        "Error_Rate": double.parse(_errorRateController.text),
        "Job_Priority": _selectedJobPriority,
        "Scheduler_Type": _selectedSchedulerType,
        "Resource_Allocation_Type": _selectedAllocationType,
      };

      final response = await http.post(
        Uri.parse('https://math-for-ml-summative.onrender.com/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _predictedCpu = data['Predicted_CPU'];
          _actionText = data['Action'];
        });
      } else {
        throw Exception('Failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Could not connect to the server.\n$e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- RESULT CARD UI ---
  Widget _buildResultCard() {
    if (_predictedCpu == null || _actionText == null) {
      return const SizedBox.shrink(); // Hide if no data
    }

    // Default to Stable (Green)
    Color chipBgColor = Colors.green.withAlpha(26);
    Color chipBorderColor = Colors.green.withAlpha(77);
    Color chipTextColor = Colors.green[800]!;
    IconData chipIcon = Icons.check_circle_outline;
    String actionLabel = _actionText!.toUpperCase();

    // Parse the Python response string (e.g., "CRITICAL - Scale Up Instantly")
    if (_actionText!.contains("CRITICAL")) {
      chipBgColor = const Color(0xFFFFF0ED); // Soft red background like image
      chipBorderColor = const Color(0x33A04401);
      chipTextColor = const Color(0xFFA04401); // Dark Rust red/orange
      chipIcon = Icons.warning_amber_rounded;
    } else if (_actionText!.contains("WARNING")) {
      chipBgColor = Colors.orange.withAlpha(26);
      chipBorderColor = Colors.orange.withAlpha(77);
      chipTextColor = Colors.orange[800]!;
      chipIcon = Icons.error_outline;
    }

    // Extract just the action part ("SCALE UP INSTANTLY") if possible
    if (_actionText!.contains(" - ")) {
      actionLabel = _actionText!.split(" - ").last.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha(13), // Subtle tint
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.only(top:24,),
            height: 170,
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PREDICTION RESULTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _predictedCpu!,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'CPU Utilization',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4E5053),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: chipBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: chipBorderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(chipIcon, color: chipTextColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        actionLabel,
                        style: TextStyle(
                          color: chipTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: SizedBox(
              width: 80,
              height: 80,
              child: Icon(Icons.trending_up_rounded, size: 80, color: Colors.grey.withAlpha(51)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(10, 0, 0, 0),
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        leading: UnconstrainedBox(
          child: SvgPicture.asset(
            'assets/icons/scaler.svg',
            semanticsLabel: 'Scaler',
            height: 24,
            width: 24,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 16.0, end: 16.0, top: 32.0),
              child: Text(
                'INFRASTRUCTURE INTELLIGENCE',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.start,
              ),
            ),
            const Padding(
              padding: EdgeInsetsDirectional.only(start: 16.0, end: 16.0, top: 8.0),
              child: Text(
                'Cloud Workload CPU Predictor',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 16.0,
                end: 16.0,
                top: 8.0,
                bottom: 16.0,
              ),
              child: Text(
                'Input real-time telemetry data to forecast cluster demand and optimize resource orchestration.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 16.0, end: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Task Start Time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'TASK START TIME',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _startTimeController,
                          validator: _requiredValidator,
                          readOnly: true,
                          onTap: () => _selectDateTime(context),
                          decoration: InputDecoration(
                            hintText: 'Select Date & Time',
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            filled: true,
                            fillColor: const Color(0xFF5F6368).withAlpha(50),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            suffixIcon: Icon(
                              Icons.calendar_month,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            errorStyle: const TextStyle(height: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Active Users
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'ACTIVE USERS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _activeUsersController, // Added Controller
                                validator: _requiredValidator,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  hintText: '509',
                                  floatingLabelBehavior: FloatingLabelBehavior.never,
                                  filled: true,
                                  fillColor: const Color(0xFF5F6368).withAlpha(50),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorStyle: const TextStyle(height: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Bandwidth
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'BANDWIDTH (MBPS)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _bandwidthController, // Added Controller
                                validator: _requiredValidator,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [_floatFormatter],
                                decoration: InputDecoration(
                                  hintText: '500',
                                  floatingLabelBehavior: FloatingLabelBehavior.never,
                                  filled: true,
                                  fillColor: const Color(0xFF5F6368).withAlpha(50),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorStyle: const TextStyle(height: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Memory Consumption
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'MEMORY CONSUMPTION (MB)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _memoryController, // Added Controller
                          validator: _requiredValidator,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [_floatFormatter],
                          decoration: InputDecoration(
                            hintText: '4096',
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            filled: true,
                            fillColor: const Color(0xFF5F6368).withAlpha(50),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            errorStyle: const TextStyle(height: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exec Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'EXEC TIME (MS)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _execTimeController, // Added Controller
                                validator: _requiredValidator,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [_floatFormatter],
                                decoration: InputDecoration(
                                  hintText: '120',
                                  floatingLabelBehavior: FloatingLabelBehavior.never,
                                  filled: true,
                                  fillColor: const Color(0xFF5F6368).withAlpha(50),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorStyle: const TextStyle(height: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Throughput
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'THROUGHPUT',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _throughputController, // Added Controller
                                validator: _requiredValidator,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [_floatFormatter],
                                decoration: InputDecoration(
                                  hintText: '45.5',
                                  floatingLabelBehavior: FloatingLabelBehavior.never,
                                  filled: true,
                                  fillColor: const Color(0xFF5F6368).withAlpha(50),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorStyle: const TextStyle(height: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Waiting Time
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'WAITING TIME (MS)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _waitingTimeController, // Added Controller
                                validator: _requiredValidator,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [_floatFormatter],
                                decoration: InputDecoration(
                                  hintText: '12',
                                  floatingLabelBehavior: FloatingLabelBehavior.never,
                                  filled: true,
                                  fillColor: const Color(0xFF5F6368).withAlpha(50),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorStyle: const TextStyle(height: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Error Rate
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'ERROR RATE (%)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _errorRateController, // Added Controller
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return 'Required';
                                  final numValue = double.tryParse(value);
                                  if (numValue == null || numValue < 0 || numValue > 100)
                                    return 'Must be 0-100';
                                  return null;
                                },
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [_floatFormatter],
                                decoration: InputDecoration(
                                  hintText: '1.5',
                                  floatingLabelBehavior: FloatingLabelBehavior.never,
                                  filled: true,
                                  fillColor: const Color(0xFF5F6368).withAlpha(50),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  errorStyle: const TextStyle(height: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Job Priority
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'JOB PRIORITY',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedJobPriority,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF5F6368).withAlpha(50),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: ['Low', 'Medium', 'High'].map((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }).toList(),
                          onChanged: (newValue) => setState(() => _selectedJobPriority = newValue!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Scheduler Type
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'SCHEDULER TYPE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedSchedulerType,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF5F6368).withAlpha(50),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: ['Round Robin', 'Priority-Based', 'FCFS', 'ASB-Dynamic-CapsNet']
                              .map((String value) {
                                return DropdownMenuItem<String>(value: value, child: Text(value));
                              })
                              .toList(),
                          onChanged: (newValue) =>
                              setState(() => _selectedSchedulerType = newValue!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Allocation Type
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'ALLOCATION TYPE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedAllocationType = 'Static'),
                                borderRadius: BorderRadius.circular(8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: _selectedAllocationType == 'Static'
                                        ? Theme.of(context).colorScheme.primary
                                        : const Color(0xFFCFE2F3),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'STATIC',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _selectedAllocationType == 'Static'
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _selectedAllocationType = 'Dynamic'),
                                borderRadius: BorderRadius.circular(8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: _selectedAllocationType == 'Dynamic'
                                        ? Theme.of(context).colorScheme.primary
                                        : const Color(0xFFCFE2F3),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'DYNAMIC',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _selectedAllocationType == 'Dynamic'
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // --- PREDICT BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        // Disable button if loading
                        onPressed: _isLoading ? null : _submitPrediction,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.analytics_outlined, color: Colors.white),
                        label: Text(
                          _isLoading ? 'Predicting...' : 'Predict',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          disabledBackgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(153),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          elevation: 0,
                        ),
                      ),
                    ),

                    // --- PREDICTION RESULTS CARD ---
                    _buildResultCard(),

                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
