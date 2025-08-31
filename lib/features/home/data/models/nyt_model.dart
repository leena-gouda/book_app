class NYTResponse {
  NYTResponse({
    required this.status,
    required this.copyright,
    required this.numResults,
    required this.results,
  });

  final String? status;
  final String? copyright;
  final int? numResults;
  final NYTResults? results;

  factory NYTResponse.fromJson(Map<String, dynamic> json){
    return NYTResponse(
      status: json["status"],
      copyright: json["copyright"],
      numResults: json["num_results"],
      results: json["results"] == null ? null : NYTResults.fromJson(json["results"]),
    );
  }

}

class NYTResults {
  NYTResults({
    required this.previousPublishedDate,
    required this.publishedDate,
    required this.nextPublishedDate,
    required this.publishedDateDescription,
    required this.bestsellersDate,
    required this.lists,
    required this.monthlyUri,
    required this.weeklyUri,
  });

  final DateTime? previousPublishedDate;
  final DateTime? publishedDate;
  final String? nextPublishedDate;
  final String? publishedDateDescription;
  final DateTime? bestsellersDate;
  final List<NYTListElement> lists;
  final String? monthlyUri;
  final String? weeklyUri;

  factory NYTResults.fromJson(Map<String, dynamic> json){
    return NYTResults(
      previousPublishedDate: DateTime.tryParse(json["previous_published_date"] ?? ""),
      publishedDate: DateTime.tryParse(json["published_date"] ?? ""),
      nextPublishedDate: json["next_published_date"],
      publishedDateDescription: json["published_date_description"],
      bestsellersDate: DateTime.tryParse(json["bestsellers_date"] ?? ""),
      lists: json["lists"] == null ? [] : List<NYTListElement>.from(json["lists"]!.map((x) => NYTListElement.fromJson(x))),
      monthlyUri: json["monthly_uri"],
      weeklyUri: json["weekly_uri"],
    );
  }

}

class NYTListElement {
  NYTListElement({
    required this.displayName,
    required this.listName,
    required this.listNameEncoded,
    required this.normalListEndsAt,
    required this.updated,
    required this.listId,
    required this.uri,
    required this.books,
    required this.corrections,
  });

  final String? displayName;
  final String? listName;
  final String? listNameEncoded;
  final int? normalListEndsAt;
  final String? updated;
  final int? listId;
  final String? uri;
  final List<NYTBook> books;
  final List<dynamic> corrections;

  factory NYTListElement.fromJson(Map<String, dynamic> json){
    return NYTListElement(
      displayName: json["display_name"],
      listName: json["list_name"],
      listNameEncoded: json["list_name_encoded"],
      normalListEndsAt: json["normal_list_ends_at"],
      updated: json["updated"],
      listId: json["list_id"],
      uri: json["uri"],
      books: json["books"] == null ? [] : List<NYTBook>.from(json["books"]!.map((x) => NYTBook.fromJson(x))),
      corrections: json["corrections"] == null ? [] : List<dynamic>.from(json["corrections"]!.map((x) => x)),
    );
  }

}

class NYTBook {
  NYTBook({
    required this.ageGroup,
    required this.amazonProductUrl,
    required this.articleChapterLink,
    required this.asterisk,
    required this.author,
    required this.bookImage,
    required this.bookImageHeight,
    required this.bookImageWidth,
    required this.bookReviewLink,
    required this.bookUri,
    required this.contributor,
    required this.contributorNote,
    required this.createdDate,
    required this.dagger,
    required this.description,
    required this.firstChapterLink,
    required this.price,
    required this.primaryIsbn10,
    required this.primaryIsbn13,
    required this.publisher,
    required this.rank,
    required this.rankLastWeek,
    required this.sundayReviewLink,
    required this.title,
    required this.updatedDate,
    required this.weeksOnList,
    required this.isbns,
    required this.buyLinks,
  });

  final String? ageGroup;
  final String? amazonProductUrl;
  final String? articleChapterLink;
  final int? asterisk;
  final String? author;
  final String? bookImage;
  final int? bookImageHeight;
  final int? bookImageWidth;
  final String? bookReviewLink;
  final String? bookUri;
  final String? contributor;
  final String? contributorNote;
  final DateTime? createdDate;
  final int? dagger;
  final String? description;
  final String? firstChapterLink;
  final String? price;
  final String? primaryIsbn10;
  final String? primaryIsbn13;
  final String? publisher;
  final int? rank;
  final int? rankLastWeek;
  final String? sundayReviewLink;
  final String? title;
  final DateTime? updatedDate;
  final int? weeksOnList;
  final List<NYTIsbn> isbns;
  final List<NYTBuyLink> buyLinks;

  factory NYTBook.fromJson(Map<String, dynamic> json){
    return NYTBook(
      ageGroup: json["age_group"],
      amazonProductUrl: json["amazon_product_url"],
      articleChapterLink: json["article_chapter_link"],
      asterisk: json["asterisk"],
      author: json["author"],
      bookImage: json["book_image"],
      bookImageHeight: json["book_image_height"],
      bookImageWidth: json["book_image_width"],
      bookReviewLink: json["book_review_link"],
      bookUri: json["book_uri"],
      contributor: json["contributor"],
      contributorNote: json["contributor_note"],
      createdDate: DateTime.tryParse(json["created_date"] ?? ""),
      dagger: json["dagger"],
      description: json["description"],
      firstChapterLink: json["first_chapter_link"],
      price: json["price"],
      primaryIsbn10: json["primary_isbn10"],
      primaryIsbn13: json["primary_isbn13"],
      publisher: json["publisher"],
      rank: json["rank"],
      rankLastWeek: json["rank_last_week"],
      sundayReviewLink: json["sunday_review_link"],
      title: json["title"],
      updatedDate: DateTime.tryParse(json["updated_date"] ?? ""),
      weeksOnList: json["weeks_on_list"],
      isbns: json["isbns"] == null ? [] : List<NYTIsbn>.from(json["isbns"]!.map((x) => NYTIsbn.fromJson(x))),
      buyLinks: json["buy_links"] == null ? [] : List<NYTBuyLink>.from(json["buy_links"]!.map((x) => NYTBuyLink.fromJson(x))),
    );
  }

  String get bestIsbn {
    if (primaryIsbn13?.isNotEmpty ?? false) return primaryIsbn13!;
    if (primaryIsbn10?.isNotEmpty ?? false) return primaryIsbn10!;
    if (isbns.isNotEmpty) return isbns.first.isbn13 ?? isbns.first.isbn10 ?? '';
    return '';
  }
  bool get hasImage => bookImage?.isNotEmpty ?? false;


}

class NYTBuyLink {
  NYTBuyLink({
    required this.name,
    required this.url,
  });

  final String? name;
  final String? url;

  factory NYTBuyLink.fromJson(Map<String, dynamic> json){
    return NYTBuyLink(
      name: json["name"],
      url: json["url"],
    );
  }

}

class NYTIsbn {
  NYTIsbn({
    required this.isbn10,
    required this.isbn13,
  });

  final String? isbn10;
  final String? isbn13;

  factory NYTIsbn.fromJson(Map<String, dynamic> json){
    return NYTIsbn(
      isbn10: json["isbn10"],
      isbn13: json["isbn13"],
    );
  }

}
