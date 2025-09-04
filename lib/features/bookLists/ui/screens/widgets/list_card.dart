import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../home/data/models/book_model.dart';
import '../../../data/models/custom_lists.dart';
import '../../../data/repos/list_repo.dart';
import '../../cubit/list_cubit.dart';

class ListCard extends StatelessWidget {
  final CustomList list;
  const ListCard({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to list details screen
        _showListDetails(context, list);
      },
      onLongPress: () {
        // Show options to edit or delete the list
        _showListOptions(context, list);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List thumbnail/header area
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: _getListColor(list.id), // Different colors for different lists
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.list_alt, size: 48, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      '${list.bookCount}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // List info area
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${list.bookCount} book${list.bookCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to generate consistent colors for lists
  Color _getListColor(int listId) {
    // Generate a consistent color based on the list ID
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    // Create a hash from the list ID to pick a consistent color
    final hash = listId.hashCode.abs();
    return colors[hash % colors.length];
  }

  // Method to show list options (edit/delete)
  void _showListOptions(BuildContext context, CustomList list) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit List Name'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditListDialog(context, list);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete List', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteListDialog(context, list);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to show edit list dialog
  void _showEditListDialog(BuildContext context, CustomList list) {
    final textController = TextEditingController(text: list.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit List Name'),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: 'Enter new list name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  context.read<ListCubit>().updateListName(list.id, textController.text);
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Method to show delete confirmation dialog
  void _showDeleteListDialog(BuildContext context, CustomList list) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete List'),
          content: Text('Are you sure you want to delete "${list.name}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<ListCubit>().deleteList(list.id);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${list.name}" deleted'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showListDetails(BuildContext context, CustomList list) {
    print('🔄 Showing details for list: ${list.name} (ID: ${list.id})');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FutureBuilder<List<Items>>( // Change to List<Items>
          future: ListRepository().getBooksInList((list.id)),
          builder: (context, snapshot) {
            print('📦 Snapshot state: ${snapshot.connectionState}');
            print('📦 Snapshot has data: ${snapshot.hasData}');

            if (snapshot.hasError) {
              print('❌ Error fetching books: ${snapshot.error}');
              return Center(child: Text('Error loading books'));
            }

            final books = snapshot.data ?? [];
            print('📚 Books count: ${books.length}');

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          list.name,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Text(
                      '${list.bookCount} book${list.bookCount == 1 ? '' : 's'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Divider(),
                    SizedBox(height: 16),

                    // Content
                    Expanded(
                      child: snapshot.connectionState == ConnectionState.waiting
                          ? Center(child: CircularProgressIndicator())
                          : books.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.list_alt, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No books in this list yet'),
                            SizedBox(height: 8),
                            Text(
                              'Add books from the book details page',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          print('🔄 Building book $index: ${book.volumeInfo?.title ?? 'Unknown'}');

                          final title = book.volumeInfo?.title ?? 'No Title';
                          final authors = book.volumeInfo?.authors?.join(', ') ?? 'Unknown Author';
                          final bookId = book.id ?? '';

                          print('🔍 Book object: ${book.toString()}');
                          print('🔍 Book ID from .id: ${book.id}');
                          print('🔍 Book data: ${book.volumeInfo?.toJson()}'); // If you have a toJson method

                          final imageUrl = book.volumeInfo?.imageLinks?.thumbnail ??
                              (bookId.isNotEmpty
                                  ? 'https://books.google.com/books/content?id=$bookId&printsec=frontcover&img=1&zoom=1&source=gbs_api'
                                  : '');

                          print('🖼️ Image URL: $imageUrl');
                          print('📝 Title: $title');
                          print('👥 Authors: $authors');

                          return ListTile(
                            leading: SizedBox(
                              width: 40,
                              height: 60,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Icon(Icons.book, color: Colors.grey, size: 20),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: Icon(Icons.broken_image, color: Colors.grey, size: 20),
                                    ),
                                  ),
                                )
                                    : Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: Icon(Icons.book, color: Colors.grey, size: 20),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              title,
                              style: TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              authors,
                              style: TextStyle(color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                if (bookId.isEmpty) {
                                  print('❌ Cannot remove book: ID is empty');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Cannot remove book: missing ID'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                print('🗑️ Removing book ID: $bookId from list: ${list.id}');
                                context.read<ListCubit>().removeBookFromList(list.id, bookId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Removed from ${list.name}'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                Navigator.pop(context);
                              },
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

}