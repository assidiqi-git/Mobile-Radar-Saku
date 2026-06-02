import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';
import '../models/transfer.dart';
import '../models/user.dart';
import '../models/wallet.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class AuthException extends ApiException {
  const AuthException() : super(statusCode: 401, message: 'Unauthenticated');
}

class ValidationException extends ApiException {
  const ValidationException({
    required super.message,
    required Map<String, dynamic> errors,
  }) : super(statusCode: 422, errors: errors);

  Map<String, List<String>> get fieldErrors {
    final result = <String, List<String>>{};
    errors?.forEach((key, value) {
      if (value is List) {
        result[key] = value.cast<String>();
      }
    });
    return result;
  }
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost/api';

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      AppConstants.clientTypeHeader: AppConstants.clientTypeMobile,
      // Skip ngrok browser warning page (required for ngrok free-tier tunnels)
      'ngrok-skip-browser-warning': 'true',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = Uri.parse('$_baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return base.replace(queryParameters: queryParams);
    }
    return base;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = response.body.isEmpty ? '{}' : response.body;

    // Guard against non-JSON responses (e.g. ngrok HTML interstitial pages)
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json') && body.trimLeft().startsWith('<')) {
      throw ApiException(
        statusCode: response.statusCode,
        message:
            'Server mengembalikan respons non-JSON (status ${response.statusCode}). '
            'Pastikan URL API sudah benar dan server aktif.',
      );
    }

    late final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Respons server tidak valid (bukan JSON).',
      );
    }

    switch (response.statusCode) {
      case 200:
      case 201:
      case 204:
        return json;
      case 401:
        throw const AuthException();
      case 422:
        throw ValidationException(
          message: json['message'] as String? ?? 'Validation failed',
          errors: json['errors'] as Map<String, dynamic>? ?? {},
        );
      default:
        throw ApiException(
          statusCode: response.statusCode,
          message: json['message'] as String? ?? 'Unexpected error',
        );
    }
  }

  // ---- Auth ----

  /// POST /login — returns token + user for mobile clients.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      _uri('/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _handleResponse(response);
  }

  /// POST /register — returns token + user for mobile clients.
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      _uri('/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );
    return _handleResponse(response);
  }

  /// POST /logout
  Future<void> logout() async {
    try {
      await http.post(_uri('/logout'), headers: _headers);
    } catch (_) {
      // Ignore errors on logout
    }
  }

  /// GET /user
  Future<UserModel> getUser() async {
    final response = await http.get(_uri('/user'), headers: _headers);
    final data = await _handleResponse(response);
    return UserModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  // ---- Wallets ----

  /// GET /wallets — fetches all pages
  Future<List<WalletModel>> getWallets() async {
    return _fetchAllPages(
      '/wallets',
      (e) => WalletModel.fromJson(e as Map<String, dynamic>),
    );
  }

  /// POST /wallets
  Future<WalletModel> storeWallet({
    required String name,
    required String type,
    double? balance,
  }) async {
    final body = <String, dynamic>{'name': name, 'type': type};
    if (balance != null) body['balance'] = balance;
    final response = await http.post(
      _uri('/wallets'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = await _handleResponse(response);
    return WalletModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// PUT /wallets/{id}
  Future<WalletModel> updateWallet(
    String id, {
    String? name,
    String? type,
    double? balance,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (type != null) body['type'] = type;
    if (balance != null) body['balance'] = balance;
    final response = await http.put(
      _uri('/wallets/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = await _handleResponse(response);
    return WalletModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// DELETE /wallets/{id}
  Future<void> deleteWallet(String id) async {
    final response = await http.delete(_uri('/wallets/$id'), headers: _headers);
    await _handleResponse(response);
  }

  // ---- Transaction Types ----

  /// GET /transaction-types — fetches all pages
  Future<List<TransactionTypeModel>> getTransactionTypes() async {
    return _fetchAllPages(
      '/transaction-types',
      (e) => TransactionTypeModel.fromJson(e as Map<String, dynamic>),
    );
  }

  // ---- Transaction Categories ----

  /// GET /transaction-categories — fetches all pages
  Future<List<TransactionCategoryModel>> getTransactionCategories() async {
    return _fetchAllPages(
      '/transaction-categories',
      (e) => TransactionCategoryModel.fromJson(e as Map<String, dynamic>),
    );
  }

  /// Generic paginated fetcher — follows `meta.last_page` cursor.
  Future<List<T>> _fetchAllPages<T>(
    String path,
    T Function(dynamic) mapper,
  ) async {
    final results = <T>[];
    int page = 1;
    int lastPage = 1;

    do {
      final response = await http.get(
        _uri(path, {'page': '$page'}),
        headers: _headers,
      );
      final data = await _handleResponse(response);

      final list = data['data'];
      if (list is List) {
        results.addAll(list.map(mapper));
      }

      // Read pagination meta if present
      final meta = data['meta'] as Map<String, dynamic>?;
      if (meta != null) {
        lastPage = (meta['last_page'] as int?) ?? 1;
      } else {
        // Non-paginated response — single page only
        break;
      }

      page++;
    } while (page <= lastPage);

    return results;
  }

  // ---- Sync ----

  /// POST /sync/transactions — push batch (max 500)
  Future<Map<String, dynamic>> pushTransactions(
      List<TransactionModel> transactions) async {
    final payload = {
      'transactions': transactions.map((t) => t.toSyncPayload()).toList(),
    };
    final response = await http.post(
      _uri('/sync/transactions'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    return _handleResponse(response);
  }

  /// GET /sync/transactions/pull?last_synced_at=
  Future<List<TransactionModel>> pullTransactions({String? lastSyncedAt}) async {
    final queryParams = lastSyncedAt != null
        ? {'last_synced_at': lastSyncedAt}
        : <String, String>{};
    final response = await http.get(
      _uri('/sync/transactions/pull', queryParams),
      headers: _headers,
    );
    final data = await _handleResponse(response);
    final list = data['data'];
    if (list is! List) return [];
    return list
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- Transfers ----

  /// POST /transfers
  Future<TransferModel> storeTransfer({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    double? fee,
    required String transferDate,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'from_wallet_id': fromWalletId,
      'to_wallet_id': toWalletId,
      'amount': amount,
      'transfer_date': transferDate,
    };
    if (fee != null) body['fee'] = fee;
    if (note != null) body['note'] = note;

    final response = await http.post(
      _uri('/transfers'),
      headers: _headers,
      body: jsonEncode(body),
    );
    final data = await _handleResponse(response);
    return TransferModel.fromJson(data['data'] as Map<String, dynamic>);
  }
}
