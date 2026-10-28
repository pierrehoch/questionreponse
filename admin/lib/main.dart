import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:question_reponse_admin/firebase_options.dart';
import 'package:question_reponse_admin/question_options.dart';
import 'package:question_reponse_admin/question_repository.dart';
import 'package:question_shared/question_shared.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Question Réponse — Administration',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3157d5)),
        useMaterial3: true,
      ),
      home: const AdminGate(),
    );
  }
}

class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingPage();
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginPage();
        }
        return FutureBuilder<IdTokenResult>(
          future: user.getIdTokenResult(true),
          builder: (context, tokenSnapshot) {
            if (!tokenSnapshot.hasData) {
              return const _LoadingPage();
            }
            if (tokenSnapshot.data!.claims?['admin'] != true) {
              return const AccessDeniedPage();
            }
            return DashboardPage(
              user: user,
              repository: QuestionRepository(FirebaseFirestore.instance),
            );
          },
        );
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(
          () => _error = switch (error.code) {
            'invalid-credential' => 'Identifiants incorrects.',
            'too-many-requests' => 'Trop de tentatives. Réessayez plus tard.',
            _ => 'Connexion impossible (${error.code}).',
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Administration',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      autofillHints: const [AutofillHints.email],
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      autofillHints: const [AutofillHints.password],
                      obscureText: true,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                      ),
                    ),
                    if (_error case final error?) ...[
                      const SizedBox(height: 12),
                      Text(error, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Se connecter'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              'Ce compte ne possède pas le rôle administrateur.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: FirebaseAuth.instance.signOut,
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.user,
    required this.repository,
    super.key,
  });

  final User user;
  final QuestionRepository repository;

  Future<void> _editQuestion(
    BuildContext context, [
    AdminQuestion? question,
  ]) async {
    List<String>? choices;
    if (question != null) {
      choices = await repository.loadChoices(question.id);
      if (!context.mounted) return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => QuestionEditorDialog(
        repository: repository,
        userId: user.uid,
        question: question,
        initialChoices: choices,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questions'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(child: Text(user.email ?? 'Administrateur')),
          ),
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: FirebaseAuth.instance.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editQuestion(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle question'),
      ),
      body: StreamBuilder<List<AdminQuestion>>(
        stream: repository.watchQuestions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final questions = snapshot.data!;
          if (questions.isEmpty) {
            return const Center(child: Text('Aucune question.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 96),
            itemCount: questions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final question = questions[index];
              return Card(
                child: ListTile(
                  title: Text(question.text),
                  subtitle: Text(_summaryLabel(question)),
                  leading: question.iconKey == null
                      ? Icon(_statusIcon(question.status))
                      : Icon(QuestionIcons.byKey(question.iconKey)?.icon),
                  onTap: question.canEdit
                      ? () => _editQuestion(context, question)
                      : null,
                  trailing: question.canEdit
                      ? IconButton(
                          tooltip: 'Supprimer',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Supprimer la question ?'),
                                content: const Text(
                                  'Cette action est irréversible.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Annuler'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Supprimer'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await repository.delete(question);
                            }
                          },
                        )
                      : const Icon(Icons.lock_outline),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _statusLabel(AdminQuestion question) {
    return switch (question.status) {
      AdminQuestionStatus.pending => 'Brouillon',
      AdminQuestionStatus.scheduled =>
        'Programmée le ${_formatDate(question.scheduledAt!)}',
      AdminQuestionStatus.published => 'Publiée',
    };
  }

  String _summaryLabel(AdminQuestion question) {
    return [
      _statusLabel(question),
      question.chartType.label,
      if (question.allowBlank) 'Vote blanc',
      if (question.allowAbstention) 'Abstention',
    ].join(' · ');
  }

  IconData _statusIcon(AdminQuestionStatus status) => switch (status) {
    AdminQuestionStatus.pending => Icons.edit_note,
    AdminQuestionStatus.scheduled => Icons.schedule,
    AdminQuestionStatus.published => Icons.public,
  };
}

class QuestionEditorDialog extends StatefulWidget {
  const QuestionEditorDialog({
    required this.repository,
    required this.userId,
    this.question,
    this.initialChoices,
    super.key,
  });

  final QuestionRepository repository;
  final String userId;
  final AdminQuestion? question;
  final List<String>? initialChoices;

  @override
  State<QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<QuestionEditorDialog> {
  late final TextEditingController _textController;
  late final TextEditingController _infoController;
  late final List<TextEditingController> _choiceControllers;
  late AdminQuestionStatus _status;
  DateTime? _scheduledAt;
  late bool _allowBlank;
  late bool _allowAbstention;
  late QuestionChartType _chartType;
  String? _iconKey;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.question?.text);
    _infoController = TextEditingController(text: widget.question?.infoText);
    _choiceControllers = (widget.initialChoices ?? ['', ''])
        .map((text) => TextEditingController(text: text))
        .toList();
    _status = widget.question?.status == AdminQuestionStatus.scheduled
        ? AdminQuestionStatus.scheduled
        : AdminQuestionStatus.pending;
    _scheduledAt = widget.question?.scheduledAt;
    _allowBlank = widget.question?.allowBlank ?? false;
    _allowAbstention = widget.question?.allowAbstention ?? false;
    _chartType = widget.question?.chartType ?? QuestionChartType.fallback;
    _iconKey = widget.question?.iconKey;
  }

  @override
  void dispose() {
    _textController.dispose();
    _infoController.dispose();
    for (final controller in _choiceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  QuestionDraft get _draft => QuestionDraft(
    text: _textController.text,
    infoText: _infoController.text,
    choices: _choiceControllers.map((controller) => controller.text).toList(),
    status: _status,
    scheduledAt: _status == AdminQuestionStatus.scheduled ? _scheduledAt : null,
    allowBlank: _allowBlank,
    allowAbstention: _allowAbstention,
    chartType: _chartType,
    iconKey: _iconKey,
  );

  Future<void> _chooseSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      initialDate: _scheduledAt ?? now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledAt ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final draft = _draft;
    final validation = validateQuestionDraft(draft);
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.save(
        draft: draft,
        userId: widget.userId,
        questionId: widget.question?.id,
      );
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _error = 'Erreur Firebase : ${error.code}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.question == null ? 'Nouvelle question' : 'Modifier la question',
      ),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _textController,
                maxLength: 500,
                decoration: const InputDecoration(labelText: 'Question'),
              ),
              TextField(
                controller: _infoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Informations complémentaires (facultatif)',
                ),
              ),
              const SizedBox(height: 16),
              Text('Choix', style: Theme.of(context).textTheme.titleMedium),
              for (var index = 0; index < _choiceControllers.length; index++)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _choiceControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Choix ${index + 1}',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _choiceControllers.length <= 2
                          ? null
                          : () => setState(() {
                              _choiceControllers.removeAt(index).dispose();
                            }),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ],
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(
                    () => _choiceControllers.add(TextEditingController()),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un choix'),
                ),
              ),
              const Divider(height: 32),
              OptionalAnswersSection(
                allowBlank: _allowBlank,
                allowAbstention: _allowAbstention,
                onChanged: ({allowBlank, allowAbstention}) => setState(() {
                  _allowBlank = allowBlank ?? _allowBlank;
                  _allowAbstention = allowAbstention ?? _allowAbstention;
                }),
              ),
              const Divider(height: 32),
              ChartTypePicker(
                selected: _chartType,
                onChanged: (type) => setState(() => _chartType = type),
              ),
              const Divider(height: 32),
              QuestionIconPicker(
                selectedKey: _iconKey,
                onChanged: (key) => setState(() => _iconKey = key),
              ),
              const Divider(height: 32),
              Text(
                'Publication',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<AdminQuestionStatus>(
                segments: const [
                  ButtonSegment(
                    value: AdminQuestionStatus.pending,
                    label: Text('Brouillon'),
                    icon: Icon(Icons.edit_note),
                  ),
                  ButtonSegment(
                    value: AdminQuestionStatus.scheduled,
                    label: Text('Programmer'),
                    icon: Icon(Icons.schedule),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: (selection) =>
                    setState(() => _status = selection.single),
              ),
              if (_status == AdminQuestionStatus.scheduled)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _scheduledAt == null
                        ? 'Date non sélectionnée'
                        : _formatDate(_scheduledAt!),
                  ),
                  trailing: OutlinedButton(
                    onPressed: _chooseSchedule,
                    child: const Text('Choisir'),
                  ),
                ),
              if (_error case final error?)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year} '
      'à ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
}
