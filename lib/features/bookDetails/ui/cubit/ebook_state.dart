part of 'ebook_cubit.dart';

@immutable
abstract class EBookState {}

class EBookInitial extends EBookState {}

class EBookLoading extends EBookState {}

class EBookAccessChecked extends EBookState {
  final bool hasAccess;
  final String? downloadUrl;
  final double price;
  final bool isEpubAvailable;
  final bool isPdfAvailable;
  final String? epubDownloadLink;
  final String? pdfDownloadLink;
  final Map<String, dynamic>? googleBooksData;

  EBookAccessChecked({
    required this.hasAccess,
    required this.downloadUrl,
    required this.price,
    required this.isEpubAvailable,
    required this.isPdfAvailable,
    this.epubDownloadLink,
    this.pdfDownloadLink,
    this.googleBooksData,
  });
}

class EBookDownloadUrlReady extends EBookState {
  final String? downloadUrl;
  final String format;

  EBookDownloadUrlReady(this.downloadUrl, this.format);
}

class EBookOpenedSuccessfully extends EBookState {}

class EBookError extends EBookState {
  final String message;

  EBookError(this.message);
}