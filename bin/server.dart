import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:crypto/crypto.dart';
import 'package:mime/mime.dart';

// Configurações globais
const String jwtSecret = 'bibliotech_secret_key_2025';
const Duration tokenDuration = Duration(minutes: 5); // ALTERADO: 5 minutos para avaliação

// Helper para resposta JSON
Response jsonResponse(Map<String, dynamic> data, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(data),
    headers: {
      'Content-Type': 'application/json',
    },
  );
}

// Banco de dados simulado em memória
class Database {
  // Hash de senhas usando SHA-256
  static String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Usuários de teste (senha com símbolos obrigatórios)
  static final Map<String, User> users = {
    'fred@fred.com': User(
      id: '1',
      email: 'fred@fred.com',
      password: _hashPassword('123abc@'),
      name: 'Frederico',
    ),
    'julia@edulib.com': User(
      id: '2',
      email: 'julia@edulib.com',
      password: _hashPassword('julia123!'),
      name: 'Júlia Silva',
    ),
    'admin@edulib.com': User(
      id: '3',
      email: 'admin@edulib.com',
      password: _hashPassword('admin2024#'),
      name: 'Admin EduLib',
    ),
  };

  // Bibliotecas com dados reais ordenadas por data de cadastro (DESC)
  static final List<Library> libraries = [
    Library(
      id: 1,
      nome: 'Biblioteca Central UFCE',
      avaliacao: 5,
      latitude: -3.7436,
      longitude: -38.5267,
      endereco: 'Campus do Pici - Fortaleza',
      foto: 'https://picsum.photos/400/300?random=1',
      dataCadastro: DateTime.parse('2024-12-15T10:00:00Z'),
    ),
    Library(
      id: 2,
      nome: 'Biblioteca Prof. Martins Filho',
      avaliacao: 4,
      latitude: -3.7319,
      longitude: -38.5267,
      endereco: 'Campus Benfica - Fortaleza',
      foto: 'https://picsum.photos/400/300?random=2',
      dataCadastro: DateTime.parse('2024-12-10T14:30:00Z'),
    ),
    Library(
      id: 3,
      nome: 'Biblioteca Setorial Engenharia',
      avaliacao: 3,
      latitude: -3.7500,
      longitude: -38.5300,
      endereco: 'Centro de Tecnologia',
      foto: 'https://picsum.photos/400/300?random=3',
      dataCadastro: DateTime.parse('2024-12-05T09:15:00Z'),
    ),
    Library(
      id: 4,
      nome: 'Biblioteca de Medicina',
      avaliacao: 4,
      latitude: -3.7300,
      longitude: -38.5200,
      endereco: 'Campus Porangabuçu',
      foto: 'https://picsum.photos/400/300?random=4',
      dataCadastro: DateTime.parse('2024-12-01T16:45:00Z'),
    ),
    Library(
      id: 5,
      nome: 'Biblioteca do Instituto de Cultura e Arte',
      avaliacao: 5,
      latitude: -3.7280,
      longitude: -38.5150,
      endereco: 'Campus Benfica - ICA',
      foto: 'https://picsum.photos/400/300?random=5',
      dataCadastro: DateTime.parse('2024-11-25T11:20:00Z'),
    ),
  ];

  // Comentários pré-populados sobre bibliotecas
  static final List<Comment> comments = [
    Comment(
      id: '1',
      libraryId: '1',
      userId: '1',
      userName: 'Frederico',
      comment: 'Excelente biblioteca! Acervo muito amplo e ambiente agradável.',
      createdAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    Comment(
      id: '2',
      libraryId: '1',
      userId: '2',
      userName: 'Júlia Silva',
      comment: 'Ótima infraestrutura e atendimento impecável. Recomendo!',
      createdAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    Comment(
      id: '3',
      libraryId: '2',
      userId: '1',
      userName: 'Frederico',
      comment: 'Biblioteca histórica com grande valor acadêmico.',
      createdAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
    Comment(
      id: '4',
      libraryId: '3',
      userId: '2',
      userName: 'Júlia Silva',
      comment: 'Especializada em engenharia, muito útil para estudantes da área.',
      createdAt: DateTime.now().subtract(Duration(hours: 6)),
    ),
  ];

  // Log de prints enviados
  static final List<PrintLog> prints = [];
}

// Modelos de dados
class User {
  final String id;
  final String email;
  final String password;
  final String name;

  User({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
      };
}

class Library {
  final int id;
  final String nome;
  final int avaliacao;
  final double latitude;
  final double longitude;
  final String endereco;
  final String foto;
  final DateTime dataCadastro;

  Library({
    required this.id,
    required this.nome,
    required this.avaliacao,
    required this.latitude,
    required this.longitude,
    required this.endereco,
    required this.foto,
    required this.dataCadastro,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'avaliacao': avaliacao,
        'latitude': latitude,
        'longitude': longitude,
        'endereco': endereco,
        'foto': foto,
        'data_cadastro': dataCadastro.toIso8601String(),
      };
}

class Comment {
  final String id;
  final String libraryId;
  final String userId;
  final String userName;
  final String comment;
  final DateTime createdAt;
  final String? parentId;

  Comment({
    required this.id,
    required this.libraryId,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.createdAt,
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'id_biblioteca': libraryId,
        'user_id': userId,
        'user_name': userName,
        'comentario': comment,
        'created_at': createdAt.toIso8601String(),
        'parent_id': parentId,
      };
}

class PrintLog {
  final String id;
  final String userId;
  final String fileName;
  final DateTime createdAt;

  PrintLog({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'file_name': fileName,
        'created_at': createdAt.toIso8601String(),
      };
}

// Utilitários para JWT
class JWTUtils {
  static String generateToken(User user) {
    final jwt = JWT({
      'sub': user.id,
      'email': user.email,
      'name': user.name,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': DateTime.now().add(tokenDuration).millisecondsSinceEpoch ~/ 1000,
    });

    return jwt.sign(SecretKey(jwtSecret));
  }

  static Map<String, dynamic>? validateToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(jwtSecret));
      final payload = jwt.payload;
      
      // Verificar se o token não expirou
      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      if (now > exp) {
        return null; // Token expirado
      }
      
      return payload;
    } catch (e) {
      return null; // Token inválido
    }
  }
}

// Middleware de autenticação
Middleware authMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Pular autenticação para endpoints específicos
      final skipAuth = [
        'generate_token',
        'validate_token',
        'motd',
        'health',
        'debug',
        'OPTIONS'
      ];
      
      final shouldSkip = skipAuth.any((path) => 
        request.url.path.contains(path) || request.method == 'OPTIONS');
      
      if (shouldSkip) {
        return innerHandler(request);
      }

      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return jsonResponse(
          {
            'error': 'Token de acesso requerido',
            'message': 'Forneça um token válido no header Authorization: Bearer <token>'
          },
          status: 401,
        );
      }

      final token = authHeader.substring(7);
      final payload = JWTUtils.validateToken(token);
      
      if (payload == null) {
        return jsonResponse(
          {
            'error': 'Token inválido ou expirado',
            'message': 'Faça login novamente para obter um token válido'
          },
          status: 401,
        );
      }

      // Adicionar informações do usuário ao request
      final updatedRequest = request.change(context: {
        'user': payload,
      });

      return innerHandler(updatedRequest);
    };
  };
}

// Classe principal da API
class BiblioTechAPI {
  final Router router = Router();

  BiblioTechAPI() {
    _setupRoutes();
  }

  void _setupRoutes() {
    // Endpoint #01 - Gerar token JWT
    router.post('/worldskills/bibliotech/jwt/generate_token', _generateToken);
    
    // Endpoint #02 - Validar token JWT
    router.post('/worldskills/bibliotech/jwt/validate_token', _validateToken);
    
    // Endpoint #03 - MOTD (Message of the Day)
    router.get('/worldskills/bibliotech/motd', _getMotd);
    
    // Endpoint #04 - Lista de bibliotecas
    router.get('/worldskills/bibliotech/library_list', _getLibraryList);
    
    // Endpoint #05 - Comentários
    router.get('/worldskills/bibliotech/comments', _getComments);
    router.post('/worldskills/bibliotech/comments', _postComment);
    
    // Endpoint #06 - Prints
    router.get('/worldskills/bibliotech/prints', _getPrints);
    router.post('/worldskills/bibliotech/prints', _postPrint);

    // Rota para servir arquivos estáticos
    router.get('/uploads/<fileName>', _getUploadedFile);
    
    // Health check
    router.get('/health', _healthCheck);
    
    // Debug: Lista todas as rotas disponíveis
    router.get('/debug/routes', _debugRoutes);
  }

  // Endpoint #01 - Autenticação
  Future<Response> _generateToken(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final email = data['email'] as String?;
      final password = data['password'] as String?;
      
      if (email == null || password == null) {
        return jsonResponse(
          {
            'error': 'Email e senha são obrigatórios',
            'message': 'Forneça email e password no body da requisição'
          },
          status: 400,
        );
      }

      // Validar formato do email
      if (!_isValidEmail(email)) {
        return jsonResponse(
          {
            'error': 'Email inválido',
            'message': 'Forneça um email válido com @ e pelo menos um ponto'
          },
          status: 400,
        );
      }

      // Validar senha (8+ chars + letras + números + símbolos)
      if (!_isValidPassword(password)) {
        return jsonResponse(
          {
            'error': 'Senha inválida',
            'message': 'A senha deve ter pelo menos 8 caracteres com letras, números e símbolos'
          },
          status: 400,
        );
      }

      final user = Database.users[email];
      if (user == null) {
        return jsonResponse(
          {
            'error': 'Usuário não encontrado',
            'message': 'Email não cadastrado no sistema'
          },
          status: 401,
        );
      }

      final hashedPassword = Database._hashPassword(password);
      if (user.password != hashedPassword) {
        return jsonResponse(
          {
            'error': 'Senha incorreta',
            'message': 'A senha fornecida não confere'
          },
          status: 401,
        );
      }

      final token = JWTUtils.generateToken(user);
      
      return jsonResponse({
        'success': true,
        'token': token,
        'user': user.toJson(),
        'expires_in': tokenDuration.inSeconds,
        'message': 'Login realizado com sucesso'
      });
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro interno do servidor',
          'message': 'Erro ao processar requisição: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Endpoint #02 - Validar token
  Future<Response> _validateToken(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final token = data['token'] as String?;
      if (token == null) {
        return jsonResponse(
          {
            'error': 'Token é obrigatório',
            'message': 'Forneça o token no campo "token"'
          },
          status: 400,
        );
      }

      final payload = JWTUtils.validateToken(token);
      if (payload == null) {
        return jsonResponse({
          'valid': false,
          'error': 'Token inválido ou expirado',
          'message': 'O token fornecido não é válido ou já expirou'
        });
      }

      return jsonResponse({
        'valid': true,
        'user': {
          'id': payload['sub'],
          'email': payload['email'],
          'name': payload['name'],
        },
        'expires_at': DateTime.fromMillisecondsSinceEpoch(
          (payload['exp'] as int) * 1000
        ).toIso8601String(),
        'message': 'Token válido'
      });
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro interno do servidor',
          'message': 'Erro ao validar token: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Endpoint #03 - Mensagem do dia
  Future<Response> _getMotd(Request request) async {
    final messages = [
      'Bem-vindo ao BiblioTech! Conectando você às melhores bibliotecas.',
      'Descubra novos mundos através dos livros em nossas bibliotecas parceiras.',
      'A educação é a chave do futuro. Encontre sua biblioteca ideal aqui.',
      'BiblioTech: onde o conhecimento encontra a tecnologia.',
      'Explore bibliotecas incríveis e amplie seus horizontes acadêmicos.',
      'Sua jornada do conhecimento começa aqui no BiblioTech.',
      'Conectando estudantes a bibliotecas de excelência.',
      'BiblioTech: seu portal para o mundo dos livros e pesquisa.',
    ];
    
    final random = Random();
    final selectedMessage = messages[random.nextInt(messages.length)];
    
    return jsonResponse({
      'message': selectedMessage,
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0'
    });
  }

  // Endpoint #04 - Lista de bibliotecas (ordenado por data_cadastro DESC)
  Future<Response> _getLibraryList(Request request) async {
    try {
      // PARA AVALIAÇÃO: Simular erro se header específico for enviado
      final forceError = request.headers['x-force-error'];
      if (forceError == 'true') {
        return jsonResponse(
          {
            'error': 'Erro simulado para avaliação',
            'message': 'Este erro foi gerado intencionalmente para teste de tratamento de erros',
            'code': 'EVALUATION_ERROR'
          },
          status: 500,
        );
      }
      
      // PARA AVALIAÇÃO: Simular erro se parâmetro específico for enviado
      final testError = request.url.queryParameters['test_error'];
      if (testError == 'biblioteca_indisponivel') {
        return jsonResponse(
          {
            'error': 'Serviço de bibliotecas temporariamente indisponível',
            'message': 'O sistema de bibliotecas está em manutenção. Tente novamente em alguns minutos.',
            'code': 'SERVICE_UNAVAILABLE',
            'retry_after': 300
          },
          status: 503,
        );
      }
      
      // Funcionamento normal
      // Ordenar bibliotecas por data de cadastro (mais recentes primeiro)
      final sortedLibraries = List<Library>.from(Database.libraries)
        ..sort((a, b) => b.dataCadastro.compareTo(a.dataCadastro));
      
      return jsonResponse({
        'success': true,
        'libraries': sortedLibraries.map((library) => library.toJson()).toList(),
        'total': sortedLibraries.length,
        'message': 'Lista de bibliotecas obtida com sucesso'
      });
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro ao buscar bibliotecas',
          'message': 'Erro interno: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Endpoint #05 - Obter comentários
  Future<Response> _getComments(Request request) async {
    try {
      final libraryId = request.url.queryParameters['id_biblioteca'];
      
      List<Comment> filteredComments = Database.comments;
      if (libraryId != null && libraryId.isNotEmpty) {
        filteredComments = Database.comments
            .where((comment) => comment.libraryId == libraryId)
            .toList();
      }
      
      // Ordenar por data de criação (mais recentes primeiro)
      filteredComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return jsonResponse({
        'success': true,
        'comments': filteredComments.map((comment) => comment.toJson()).toList(),
        'total': filteredComments.length,
        'id_biblioteca': libraryId,
        'message': 'Comentários obtidos com sucesso'
      });
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro ao buscar comentários',
          'message': 'Erro interno: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Endpoint #05 - Adicionar comentário
  Future<Response> _postComment(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final user = request.context['user'] as Map<String, dynamic>;
      
      final libraryId = data['id_biblioteca'] as String?;
      final commentText = data['comentario'] as String?;
      final parentId = data['parent_id'] as String?;
      
      if (libraryId == null || commentText == null || commentText.trim().isEmpty) {
        return jsonResponse(
          {
            'error': 'Dados obrigatórios ausentes',
            'message': 'id_biblioteca e comentario são obrigatórios'
          },
          status: 400,
        );
      }

      // Verificar se a biblioteca existe
      final libraryExists = Database.libraries.any((lib) => lib.id.toString() == libraryId);
      if (!libraryExists) {
        return jsonResponse(
          {
            'error': 'Biblioteca não encontrada',
            'message': 'ID da biblioteca fornecido não existe'
          },
          status: 404,
        );
      }

      // Verificar comentário pai se fornecido
      if (parentId != null) {
        final parentExists = Database.comments.any((c) => c.id == parentId);
        if (!parentExists) {
          return jsonResponse(
            {
              'error': 'Comentário pai não encontrado',
              'message': 'parent_id fornecido não existe'
            },
            status: 404,
          );
        }
      }

      final newComment = Comment(
        id: (Database.comments.length + 1).toString(),
        libraryId: libraryId,
        userId: user['sub'],
        userName: user['name'],
        comment: commentText.trim(),
        createdAt: DateTime.now(),
        parentId: parentId,
      );

      Database.comments.add(newComment);
      
      return jsonResponse({
        'success': true,
        'message': 'Comentário adicionado com sucesso',
        'comment': newComment.toJson(),
      });
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro ao adicionar comentário',
          'message': 'Erro interno: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Endpoint #06 - Listar prints
  Future<Response> _getPrints(Request request) async {
    try {
      final user = request.context['user'] as Map<String, dynamic>?;
      final userId = request.url.queryParameters['user_id'] ?? user?['sub'];
      
      List<PrintLog> filteredPrints = Database.prints;
      if (userId != null) {
        filteredPrints = Database.prints
            .where((print) => print.userId == userId)
            .toList();
      }
      
      // Ordenar por data (mais recentes primeiro)
      filteredPrints.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return jsonResponse({
        'success': true,
        'prints': filteredPrints.map((print) => print.toJson()).toList(),
        'total': filteredPrints.length,
        'message': 'Lista de prints obtida com sucesso'
      });
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro ao listar prints',
          'message': 'Erro interno: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Endpoint #06 - Upload de print
  Future<Response> _postPrint(Request request) async {
    try {
      final contentType = request.headers['content-type'];
      final user = request.context['user'] as Map<String, dynamic>;
      
      // Aceitar tanto JSON quanto multipart
      if (contentType != null && contentType.contains('application/json')) {
        // Modo JSON (simulado)
        final body = await request.readAsString();
        final data = jsonDecode(body);
        
        final userId = data['id_user'] as String?;
        
        if (userId == null) {
          return jsonResponse(
            {
              'error': 'Dados obrigatórios ausentes',
              'message': 'id_user é obrigatório'
            },
            status: 400,
          );
        }
        
        // Criar diretório uploads se não existir
        final uploadsDir = Directory('uploads');
        if (!await uploadsDir.exists()) {
          await uploadsDir.create(recursive: true);
        }
        
        // Simular arquivo
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'print_bibliotech_$timestamp.png';
        
        // Criar arquivo de exemplo
        final file = File('uploads/$fileName');
        await file.writeAsString('Print BiblioTech via JSON - ${DateTime.now()}');

        final printLog = PrintLog(
          id: (Database.prints.length + 1).toString(),
          userId: userId,
          fileName: fileName,
          createdAt: DateTime.now(),
        );

        Database.prints.add(printLog);
        
        return jsonResponse({
          'success': true,
          'message': 'Print enviado com sucesso',
          'print': printLog.toJson(),
          'file_url': '/uploads/$fileName',
          'mode': 'JSON simulado'
        });
        
      } else if (contentType != null && contentType.contains('multipart/form-data')) {
        // Modo multipart (simplificado)
        
        // Criar diretório uploads se não existir
        final uploadsDir = Directory('uploads');
        if (!await uploadsDir.exists()) {
          await uploadsDir.create(recursive: true);
        }
        
        // Simular processamento do multipart
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'print_bibliotech_multipart_$timestamp.png';
        
        // Criar arquivo de exemplo
        final file = File('uploads/$fileName');
        await file.writeAsString('Print BiblioTech via multipart - ${DateTime.now()}');

        final printLog = PrintLog(
          id: (Database.prints.length + 1).toString(),
          userId: user['sub'],
          fileName: fileName,
          createdAt: DateTime.now(),
        );

        Database.prints.add(printLog);
        
        return jsonResponse({
          'success': true,
          'message': 'Print enviado com sucesso',
          'print': printLog.toJson(),
          'file_url': '/uploads/$fileName',
          'mode': 'Multipart'
        });
        
      } else {
        return jsonResponse(
          {
            'error': 'Formato inválido',
            'message': 'Use Content-Type: application/json ou multipart/form-data'
          },
          status: 400,
        );
      }
      
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro ao processar upload',
          'message': 'Erro interno: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Servir arquivos estáticos
  Future<Response> _getUploadedFile(Request request, String fileName) async {
    try {
      final file = File('uploads/$fileName');
      if (!await file.exists()) {
        return jsonResponse(
          {
            'error': 'Arquivo não encontrado',
            'message': 'O arquivo solicitado não existe'
          },
          status: 404,
        );
      }

      final bytes = await file.readAsBytes();
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';

      return Response.ok(
        bytes,
        headers: {
          'Content-Type': mimeType,
          'Content-Length': bytes.length.toString(),
          'Cache-Control': 'public, max-age=86400', // Cache por 24h
        },
      );
    } catch (e) {
      return jsonResponse(
        {
          'error': 'Erro ao servir arquivo',
          'message': 'Erro interno: ${e.toString()}'
        },
        status: 500,
      );
    }
  }

  // Health check
  Future<Response> _healthCheck(Request request) async {
    return jsonResponse({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'api': 'BiblioTech',
      'endpoints': {
        'auth': '/worldskills/bibliotech/jwt/generate_token',
        'libraries': '/worldskills/bibliotech/library_list',
        'comments': '/worldskills/bibliotech/comments',
        'prints': '/worldskills/bibliotech/prints'
      }
    });
  }

  // Debug: Listar rotas disponíveis
  Future<Response> _debugRoutes(Request request) async {
    return jsonResponse({
      'available_routes': [
        'POST /worldskills/bibliotech/jwt/generate_token - Autenticação',
        'POST /worldskills/bibliotech/jwt/validate_token - Validar token',
        'GET  /worldskills/bibliotech/motd - Mensagem do dia',
        'GET  /worldskills/bibliotech/library_list - Lista de bibliotecas',
        'GET  /worldskills/bibliotech/comments - Comentários',
        'POST /worldskills/bibliotech/comments - Adicionar comentário',
        'GET  /worldskills/bibliotech/prints - Lista de prints',
        'POST /worldskills/bibliotech/prints - Upload de print',
        'GET  /uploads/<fileName> - Arquivos estáticos',
        'GET  /health - Health check',
        'GET  /debug/routes - Esta rota'
      ],
      'note': 'Todos os endpoints (exceto auth, validate e motd) requerem Authorization: Bearer <token>',
      'api': 'BiblioTech API v1.0',
      'company': 'EduLib'
    });
  }

  // Validação de email
  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.') && email.length > 5;
  }

  // Validação de senha (8+ chars + letras + números + símbolos obrigatórios)
  bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    
    bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return hasLetter && hasNumber && hasSymbol;
  }

  // Handler principal com middlewares
  Handler get handler => Pipeline()
      .addMiddleware(corsHeaders(
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Requested-With',
          'Access-Control-Max-Age': '86400',
        }
      ))
      .addMiddleware(authMiddleware())
      .addMiddleware(logRequests())
      .addHandler(router);
}

// Função principal
void main() async {
  final api = BiblioTechAPI();
  
  // Criar diretório uploads se não existir
  final uploadsDir = Directory('uploads');
  if (!await uploadsDir.exists()) {
    await uploadsDir.create(recursive: true);
  }
  
  // Configuração de porta e host
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final host = Platform.environment['HOST'] ?? '0.0.0.0';
  
  final server = await serve(
    api.handler,
    host,
    port,
  );
  
  // Logs de inicialização
  print('🚀 BiblioTech API executando em http://$host:$port');
  print('🌐 Empresa: EduLib');
  print('🔑 JWT Secret: ${jwtSecret.substring(0, 15)}...');
  print('⏰ Token Duration: ${tokenDuration.inMinutes} minutos'); // ALTERADO
  print('');
  print('📚 Endpoints disponíveis:');
  print('   POST /worldskills/bibliotech/jwt/generate_token - Autenticação');
  print('   POST /worldskills/bibliotech/jwt/validate_token - Validar token');
  print('   GET  /worldskills/bibliotech/motd - Mensagem do dia');
  print('   GET  /worldskills/bibliotech/library_list - Lista de bibliotecas');
  print('   GET  /worldskills/bibliotech/comments - Comentários');
  print('   POST /worldskills/bibliotech/comments - Adicionar comentário');
  print('   GET  /worldskills/bibliotech/prints - Lista de prints');
  print('   POST /worldskills/bibliotech/prints - Upload de print');
  print('   GET  /health - Health check');
  print('');
  print('👤 Usuários de teste:');
  print('   fred@fred.com / 123abc@');
  print('   julia@edulib.com / julia123!');
  print('   admin@edulib.com / admin2024#');
  print('');
  print('🏛️ Bibliotecas cadastradas: ${Database.libraries.length}');
  print('✅ BiblioTech API pronta para receber conexões!');
}