import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PipelineResponse {
  final String status;
  final String language;
  final String transcription;
  final String? nativeTranscription;
  final String? englishQuery;
  final String? englishAnswer;
  final String answerNative;
  final String? audioUrl;

  PipelineResponse({
    required this.status,
    required this.language,
    required this.transcription,
    this.nativeTranscription,
    this.englishQuery,
    this.englishAnswer,
    required this.answerNative,
    this.audioUrl,
  });

  factory PipelineResponse.fromJson(Map<String, dynamic> json) {
    return PipelineResponse(
      status: json['status'] ?? 'success',
      language: json['language'] ?? '',
      transcription: json['transcription'] ?? '',
      nativeTranscription: json['native_transcription'],
      englishQuery: json['english_query'],
      englishAnswer: json['english_answer'],
      answerNative: json['answer_native'] ?? '',
      audioUrl: json['audio_url'],
    );
  }
}

class ApiService {
  final String baseUrl;

  ApiService({String? baseUrl})
      : baseUrl = baseUrl ?? 'http://127.0.0.1:8000';

  /// Sends selected language and recorded audio file to FastAPI backend
  Future<PipelineResponse> processVoiceQuery({
    required String audioFilePath,
    required String languageCode,
  }) async {
    final uri = Uri.parse('$baseUrl/api/process_voice');
    final request = http.MultipartRequest('POST', uri);

    request.fields['language'] = languageCode;

    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('Audio recording file not found at path: $audioFilePath');
    }

    final multipartFile = await http.MultipartFile.fromPath(
      'audio',
      audioFilePath,
    );
    request.files.add(multipartFile);

    debugPrint('Sending voice query to FastAPI: language=$languageCode, file=$audioFilePath');

    final streamedResponse = await request.send().timeout(
          const Duration(seconds: 120),
          onTimeout: () {
            throw Exception('Backend connection timed out after 120 seconds.');
          },
        );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      debugPrint('FastAPI Pipeline Response received successfully: ${data['answer_native']}');
      return PipelineResponse.fromJson(data);
    } else {
      String errorMessage = 'FastAPI server returned status ${response.statusCode}';
      try {
        final errJson = json.decode(response.body);
        if (errJson is Map && errJson.containsKey('detail')) {
          errorMessage = errJson['detail'].toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
