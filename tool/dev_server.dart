import 'dart:async';
import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  print('=====================================================');
  print('🚀 Iniciando Flutter Dev Server com Auto-Reload...');
  print('📁 Monitorando alterações na pasta: lib/');
  print('🌐 URL: http://localhost:8080');
  print('=====================================================\n');

  final bool isWindows = Platform.isWindows;
  final String executable = isWindows ? 'flutter.bat' : 'flutter';

  // Inicia o processo do Flutter
  final process = await Process.start(
    executable,
    [
      'run',
      '-d',
      'web-server',
      '--web-hostname',
      'localhost',
      '--web-port',
      '8080',
    ],
    runInShell: true,
    mode: ProcessStartMode.normal,
  );

  // Redireciona a saída do Flutter para o console
  process.stdout.transform(utf8.decoder).listen((data) {
    stdout.write(data);
  });

  process.stderr.transform(utf8.decoder).listen((data) {
    stderr.write(data);
  });

  // Redireciona entrada do usuário se houver
  stdin.transform(utf8.decoder).listen((data) {
    process.stdin.write(data);
  });

  // Monitoramento de arquivos da pasta lib
  final libDir = Directory('lib');
  Timer? debounceTimer;
  bool isReady = false;

  // Dá um tempo inicial para o flutter compilar e iniciar antes de monitorar
  Timer(const Duration(seconds: 15), () {
    isReady = true;
    print('\n[Auto-Reload] 🟢 Monitoramento ativo! Salvar qualquer arquivo recarregará o app automaticamente.\n');
  });

  if (await libDir.exists()) {
    libDir.watch(recursive: true).listen((event) {
      if (!isReady) return;
      if (!event.path.endsWith('.dart')) return;

      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 600), () {
        final fileName = event.path.split(Platform.pathSeparator).last;
        print('\n[Auto-Reload] ⚡ Alteração detectada em "$fileName". Enviando Hot Reload (r)...');
        process.stdin.writeln('r');
      });
    });
  }

  // Monitora pubspec.yaml se necessário
  final pubspecFile = File('pubspec.yaml');
  if (await pubspecFile.exists()) {
    pubspecFile.watch().listen((event) {
      if (!isReady) return;
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 600), () {
        print('\n[Auto-Reload] ⚡ pubspec.yaml alterado. Enviando Hot Restart (R)...');
        process.stdin.writeln('R');
      });
    });
  }

  // Aguarda encerramento do processo
  final exitCode = await process.exitCode;
  print('\n[Auto-Reload] Servidor encerrado com código: $exitCode');
  exit(exitCode);
}
