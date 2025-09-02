import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../home/data/models/book_model.dart';
import '../../cubit/list_cubit.dart';

class AddToListBottomSheet extends StatelessWidget {
  final Items book;

  const AddToListBottomSheet({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add to List',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
              ),
            ],
          ),
          Divider(),
          SizedBox(height: 16),

          BlocBuilder<ListCubit, ListState>(
            builder: (context, state) {
              if (state is ListLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (state is ListError) {
                return Center(child: Text('Error: ${state.message}'));
              }

              if (state is ListLoaded) {
                final lists = state.lists;

                if (lists.isEmpty) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No lists yet'),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              showCreateListDialog(context);
                            },
                            child: Text('Create New List'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: lists.length,
                    itemBuilder: (context, index) {
                      final list = lists[index];
                      return ListTile(
                        leading: Icon(Icons.list_alt),
                        title: Text(list.name),
                        subtitle: Text('${list.bookCount} books'),
                        onTap: () {
                          context.read<ListCubit>().addBookToList(
                              list.id,
                              book.id ?? 'unknown_id',
                              book
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added to ${list.name}'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              }

              return Container();
            },
          ),

          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showCreateListDialog(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 20),
                SizedBox(width: 8),
                Text('Create New List'),
              ],
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }
}

void showCreateListDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      final textController = TextEditingController();

      return AlertDialog(
        title: Text('Create New List'),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: 'Enter list name',
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
                context.read<ListCubit>().createList(textController.text);
                Navigator.pop(context);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('List created successfully'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text('Create'),
          ),
        ],
      );
    },
  );
}