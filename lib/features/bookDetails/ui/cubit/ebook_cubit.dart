import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/ebook_repo.dart';

part 'ebook_state.dart';

class EBookCubit extends Cubit<EBookState> {
  final EBookRepository repository;

  EBookCubit(this.repository) : super(EBookInitial());

  Future<void> checkEbookAccess(String bookId) async {
    emit(EBookLoading());
    try {
      final hasAccess = await repository.checkEbookAccess(bookId);
      final downloadUrl = await repository.getEbookDownloadUrl(bookId);
      final details = await repository.getEbookDetails(bookId);

      emit(EBookAccessChecked(
        hasAccess: hasAccess,
        downloadUrl: downloadUrl,
        price: (details['price'] as num?)?.toDouble() ?? 0.0,
        isEpubAvailable: details['isEpubAvailable'] as bool,
        isPdfAvailable: details['isPdfAvailable'] as bool,
        epubDownloadLink: details['epubDownloadLink'] as String?,
        pdfDownloadLink: details['pdfDownloadLink'] as String?,
        googleBooksData: details['googleBooksData'] as Map<String, dynamic>?,
      ));
    } catch (e) {
      print('Error in checkEbookAccess: $e');
      emit(EBookError('Failed to check eBook access'));
    }
  }

  // Add this new method to get book content
  Future<Map<String, dynamic>> getBookContent(String bookId) async {
    try {
      final downloadUrl = await repository.getEbookDownloadUrl(bookId);
      final details = await repository.getEbookDetails(bookId);

      return {
        'type': 'webview',
        'url': downloadUrl,
        'title': details['title'] ?? 'E-Book Reader',
        'isEpubAvailable': details['isEpubAvailable'],
        'isPdfAvailable': details['isPdfAvailable'],
        'epubDownloadLink': details['epubDownloadLink'],
        'pdfDownloadLink': details['pdfDownloadLink'],
      };
    } catch (e) {
      print('Error getting book content: $e');
      return {
        'type': 'error',
        'message': 'No content available for this book.'
      };
    }
  }

  Future<String?> downloadEpub(String bookId) async {
    try {
      emit(EBookLoading());
      final downloadUrl = await repository.downloadEpub(bookId);
      emit(EBookDownloadUrlReady(downloadUrl, 'epub'));
      return downloadUrl;
    } catch (e) {
      emit(EBookError('Failed to get EPUB download link: $e'));
      return null;
    }
  }

  Future<String?> downloadPdf(String bookId) async {
    try {
      emit(EBookLoading());
      final downloadUrl = await repository.downloadPdf(bookId);
      emit(EBookDownloadUrlReady(downloadUrl, 'pdf'));
      return downloadUrl;
    } catch (e) {
      emit(EBookError('Failed to get PDF download link: $e'));
      return null;
    }
  }

  // Add this to your EBookCubit
  bool _isPurchasing = false;

  Future<void> purchaseEbook(String bookId, double price) async {
    if (_isPurchasing) return; // Prevent multiple purchases

    _isPurchasing = true;
    emit(EBookLoading());

    try {
      final success = await repository.purchaseEbook(bookId, price);
      if (success) {
        // Clear any purchase flags and re-check access
        _isPurchasing = false;
        await checkEbookAccess(bookId);
      } else {
        _isPurchasing = false;
        emit(EBookError('Failed to complete purchase'));
      }
    } catch (e) {
      _isPurchasing = false;
      emit(EBookError('Purchase failed: $e'));
    }
  }

  Future<void> updateReadingProgress(String bookId, int currentPage, double progress, String status) async {
    try {
      final success = await repository.updateReadingProgress(bookId, currentPage, progress, status);
      if (!success) {
        emit(EBookError('Failed to update reading progress'));
      }
    } catch (e) {
      emit(EBookError('Error updating progress: $e'));
    }
  }

  Future<void> updateBookStatus(String bookId, String status) async {
    try {
      final success = await repository.updateBookStatus(bookId, status);
      if (!success) {
        emit(EBookError('Failed to update book status'));
      }
    } catch (e) {
      emit(EBookError('Error updating status: $e'));
    }
  }

  Future<void> loadUserLibrary() async {
    emit(EBookLoading());
    try {
      final library = await repository.getUserLibrary();
      // You might want to create a new state for library data
      emit(EBookAccessChecked(hasAccess: true, downloadUrl: null, price: 0.0, isEpubAvailable: false, isPdfAvailable: false));
    } catch (e) {
      emit(EBookError('Failed to load library: $e'));
    }
  }

  Future<void> openEbook(String bookId, {String? customUrl}) async {
    try {
      emit(EBookLoading());

      final url = customUrl ?? await repository.getEbookDownloadUrl(bookId);

      if (url == null) {
        emit(EBookError('No eBook URL available'));
        return;
      }

      // For webview, we navigate to the reader screen instead of launching URL
      // The URL will be handled by the EBookReaderScreen
      emit(EBookOpenedSuccessfully());

    } catch (e) {
      emit(EBookError('Failed to open eBook: $e'));
    }
  }

  void resetState() {
    emit(EBookInitial());
  }
}