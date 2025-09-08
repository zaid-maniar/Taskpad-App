import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String kTasksBox = 'tasksBox';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>(kTasksBox);
  runApp(const TaskPadApp());
}

class TaskPadApp extends StatelessWidget {
  const TaskPadApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MODIFIED: Dark grey + yellow Material 3 color scheme
    const Color darkGrey = Color(0xFF121212);      // base background
    const Color surfaceGrey = Color(0xFF1E1E1E);   // cards/surfaces
    const Color outlineGrey = Color(0xFF2A2A2A);   // borders/dividers
    const Color accentYellow = Color(0xFFFFD700);  // gold/yellow accent
    const Color onDark = Color(0xFFEAEAEA);

    final ColorScheme scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: accentYellow,
      onPrimary: Colors.black,
      secondary: accentYellow,
      onSecondary: Colors.black,
      error: const Color(0xFFCF6679),
      onError: Colors.black,
      background: darkGrey,
      onBackground: onDark,
      surface: surfaceGrey,
      onSurface: onDark,
      // Material 3 extras
      surfaceTint: Colors.transparent,
      outline: outlineGrey,
      tertiary: accentYellow,
      onTertiary: Colors.black,
      inverseSurface: const Color(0xFF2C2C2C),
      onInverseSurface: onDark,
      shadow: Colors.black,
      scrim: Colors.black54,
    );

    final ThemeData theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
      ),
      listTileTheme: ListTileThemeData(
        tileColor: scheme.surface,
        textColor: scheme.onSurface,
        iconColor: scheme.onSurface.withOpacity(0.8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        // MODIFIED: Increased vertical padding to make TextField taller
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      dividerColor: scheme.outline,
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.onSurface.withOpacity(0.5);
        }),
        side: BorderSide(color: scheme.onSurface.withOpacity(0.6)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surface,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        actionTextColor: scheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    return MaterialApp(
      title: 'TaskPad',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const TaskHomePage(),
    );
  }
}

class TaskHomePage extends StatefulWidget {
  const TaskHomePage({super.key});

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  final TextEditingController _controller = TextEditingController();
  late final Box<String> _box;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<String>(kTasksBox);
  }

  void _addTask(String text) {
    final task = text.trim();
    if (task.isEmpty) return;
    _box.add(task);
    _controller.clear();
  }

  void _deleteTask(int index) {
    _box.deleteAt(index);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted')),
      );
    }
  }

  void _editTask(int index, String current) async {
    final controller = TextEditingController(text: current);
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('Edit Task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.of(ctx).pop(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final updated = controller.text.trim();
              if (updated.isNotEmpty) {
                _box.putAt(index, updated);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaskPad'),
        // REMOVED: The actions property containing the 'Click' button
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _addTask,
                    decoration: const InputDecoration(
                      hintText: 'Write a task...',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _addTask(_controller.text),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (context, Box<String> box, _) {
                if (box.isEmpty) {
                  return Center(
                    child: Text(
                      'No tasks yet.\nAdd the first one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.7),
                        fontSize: 16,
                        height: 1.3,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                  itemCount: box.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = box.getAt(index) ?? '';
                    return Dismissible(
                      key: ValueKey('task_$index'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteTask(index),
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          title: Text(
                            task,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: Icon(Icons.note_alt_outlined, color: scheme.primary),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editTask(index, task),
                            tooltip: 'Edit',
                          ),
                          onLongPress: () => _deleteTask(index),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTask(_controller.text),
        icon: const Icon(Icons.save_alt),
        label: const Text('Save'),
      ),
    );
  }
}
