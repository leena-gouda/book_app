import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/home_cubit.dart';

class BookSearchDelegate extends SearchDelegate {
  // This controls the initial query and the suggestion list
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          if (query.isEmpty) {
            close(context, null); // Close if query is empty
          } else {
            query = ''; // Clear the search field
          }
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  // Leading icon on the left of the app bar
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null), // Close the search page
      icon: const Icon(Icons.arrow_back),
    );
  }

  // The results shown after the user presses 'search' or selects a suggestion
  @override
  Widget buildResults(BuildContext context) {
    // This is the key part: When the user submits a search or selects a suggestion,
    // we trigger the search in our Cubit and display the results.
    if (query.length < 2) {
      return const Center(
        child: Text('Enter at least 2 characters to search'),
      );
    }

    // Access the Cubit and trigger the search
    final cubit = BlocProvider.of<HomeCubit>(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cubit.searchBooks(query);
    });

    // Return a BlocBuilder to listen to the state and display results
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is HomeError) {
          return Center(child: Text('Error: ${state.message}'));
        } else if (state is HomeSuccess) {
          final books = state.books;
          if (books.isEmpty) {
            return const Center(child: Text('No books found'));
          }
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                leading: book.volumeInfo?.imageLinks?.thumbnail != null
                    ? Image.network(book.volumeInfo?.imageLinks?.thumbnail ?? '', width: 50, fit: BoxFit.cover)
                    : const Icon(Icons.book),
                title: Text(book.volumeInfo?.title ?? 'No Title'),
                subtitle: Text(book.volumeInfo?.authors?.join(', ') ?? 'Unknown Author'),
                onTap: () {
                  // You can navigate to a book details page here
                  close(context, books); // Close search and return the selected book
                },
              );
            },
          );
        } else {
          return const Center(child: Text('Start typing to search for books'));
        }
      },
    );
  }

  // Suggestions shown as the user types
  @override
  Widget buildSuggestions(BuildContext context) {
    // For a simple app, you can show recent searches or popular suggestions.
    // For now, let's just show a message. You can enhance this later.
    if (query.isEmpty) {
      return const Center(
        child: Text('Type to search for books...'),
      );
    }

    // You could also trigger a "quick search" here for suggestions,
    // but for the MVP, we'll just show a loading message that leads to results.
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.search),
          title: Text('Search for "$query"'),
          onTap: () {
            // This moves the query to the "results" screen and triggers the search
            showResults(context);
          },
        ),
      ],
    );
  }
}