import 'package:book_app/features/bookDetails/ui/screens/widgets/ebook_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/ebook_cubit.dart';

class EBookAccessDialog extends StatelessWidget {
  final bool hasAccess;
  final String? downloadUrl;
  final String ebookUrl;
  final String bookTitle;
  final String bookId;
  final VoidCallback onPurchase;
  final VoidCallback onDownload;

  const EBookAccessDialog({
    super.key,
    required this.hasAccess,
    this.downloadUrl,
    required this.ebookUrl,
    required this.bookTitle,
    required this.bookId,
    required this.onPurchase,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(hasAccess ? 'eBook Available' : 'Purchase Required'),
      content: Text(hasAccess
          ? 'You can read or download "$bookTitle"'
          : 'Purchase required to access "$bookTitle"'),
      actions: [
        if (!hasAccess)
          TextButton(
            onPressed: onPurchase,
            child: const Text('Purchase'),
          ),
        // In EBookAccessDialog, update the Read Now button:
        if (hasAccess)
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(child: CircularProgressIndicator()),
              );

              try {
                // You'll need to pass the cubit or repository to the dialog
                // or use a different approach to get the content
                final ebookCubit = context.read<EBookCubit>();
                final bookContent = await ebookCubit.getBookContent(bookId);

                Navigator.pop(context); // Close loading dialog

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EBookReaderScreen(
                      bookTitle: bookTitle,
                      bookContent: bookContent,
                    ),
                  ),
                );
              } catch (e) {
                Navigator.pop(context); // Close loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load book content: $e')),
                );
              }
            },
            child: const Text('Read Now'),
          ),
        if (hasAccess && downloadUrl != null)
          TextButton(
            onPressed: onDownload,
            child: const Text('Download'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}