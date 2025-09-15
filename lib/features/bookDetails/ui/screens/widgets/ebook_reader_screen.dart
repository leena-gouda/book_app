import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EBookReaderScreen extends StatefulWidget {
  final String bookTitle;
  final Map<String, dynamic> bookContent;

  const EBookReaderScreen({
    super.key,
    required this.bookTitle,
    required this.bookContent,
  });

  @override
  State<EBookReaderScreen> createState() => _EBookReaderScreenState();
}

class _EBookReaderScreenState extends State<EBookReaderScreen> {
  late final WebViewController? _webViewController;
  int _currentPage = 0;
  final PageController _pageController = PageController();
  late List<String> _pages;
  double _fontSize = 18.0;
  Color _backgroundColor = const Color(0xFFF5F5F5);
  Color _textColor = Colors.black;
  bool _showControls = false;
  double _lineHeight = 1.6;
  bool _isLoading = true;
  double _progress = 0;
  bool _isWebView = false;

  @override
  void initState() {
    super.initState();

    _isWebView = widget.bookContent['type'] == 'webview';

    if (_isWebView) {
      // Handle webview content
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
          },
        ))
        ..loadRequest(Uri.parse(widget.bookContent['url']));
    } else {
      // Handle text content
      _webViewController = null;
      final content = widget.bookContent['content'] ?? widget.bookContent['message'] ?? 'No content available';
      _splitContentIntoPages(content);
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  void _splitContentIntoPages(String content) {
    final pages = <String>[];

    // Split by chapters if they exist
    final chapterPattern = RegExp(r'(## Chapter \d+|# Chapter \d+)');
    final chapters = content.split(chapterPattern);

    if (chapters.length > 1) {
      // Add chapter titles and content
      for (int i = 1; i < chapters.length; i++) {
        final chapterMatch = chapterPattern.allMatches(content).elementAt(i - 1);
        final chapterTitle = chapterMatch.group(0);
        pages.add('$chapterTitle\n\n${chapters[i].trim()}');
      }
    } else {
      // Fallback: split by approximate page length
      final words = content.split(' ');
      String currentPageContent = '';
      int wordCount = 0;
      const int wordsPerPage = 250;

      for (final word in words) {
        if (wordCount >= wordsPerPage && (word.endsWith('.') || word.endsWith('."'))) {
          pages.add(currentPageContent);
          currentPageContent = '';
          wordCount = 0;
        }
        currentPageContent += '$word ';
        wordCount++;
      }

      if (currentPageContent.isNotEmpty) {
        pages.add(currentPageContent);
      }
    }

    setState(() {
      _pages = pages;
    });
  }

  void _toggleControls() {
    if (!_isWebView) {
      setState(() {
        _showControls = !_showControls;
      });
    }
  }

  void _increaseFontSize() {
    if (!_isWebView) {
      setState(() {
        _fontSize += 1.0;
      });
    }
  }

  void _decreaseFontSize() {
    if (!_isWebView) {
      setState(() {
        if (_fontSize > 14.0) {
          _fontSize -= 1.0;
        }
      });
    }
  }

  void _toggleDarkMode() {
    if (!_isWebView) {
      setState(() {
        if (_backgroundColor == const Color(0xFFF5F5F5)) {
          _backgroundColor = const Color(0xFF1E1E1E);
          _textColor = Colors.white;
        } else {
          _backgroundColor = const Color(0xFFF5F5F5);
          _textColor = Colors.black;
        }
      });
    }
  }

  Widget _buildPageContent(String content) {
    final isChapter = content.startsWith('## Chapter') || content.startsWith('# Chapter');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isChapter)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.split('\n').first,
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Text(
                    content.substring(content.indexOf('\n') + 1).trim(),
                    style: TextStyle(
                      fontSize: _fontSize,
                      color: _textColor,
                      height: _lineHeight,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              )
            else
              Text(
                content,
                style: TextStyle(
                  fontSize: _fontSize,
                  color: _textColor,
                  height: _lineHeight,
                ),
                textAlign: TextAlign.justify,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController!),
        if (_isLoading)
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
      ],
    );
  }

  Widget _buildTextReader() {
    return GestureDetector(
      onTap: _toggleControls,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _pages.length,
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        itemBuilder: (context, index) {
          return _buildPageContent(_pages[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isWebView ? Colors.white : _backgroundColor,
      appBar: _isWebView
          ? AppBar(
        title: Text(widget.bookTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
          ),
          IconButton(
            icon: Icon(Icons.open_in_browser),
            onPressed: () => _launchDownloadUrl(widget.bookContent['url'], 'web'),
          ),
        ],
      )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            _isWebView ? _buildWebView() : _buildTextReader(),

            // Controls for text reader
            if (!_isWebView && _showControls) ...[
              // Top controls
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.bookTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: _backgroundColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16.0),
                                    topRight: Radius.circular(16.0),
                                  ),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.text_increase),
                                      title: const Text('Increase Font Size'),
                                      onTap: () {
                                        _increaseFontSize();
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.text_decrease),
                                      title: const Text('Decrease Font Size'),
                                      onTap: () {
                                        _decreaseFontSize();
                                        Navigator.pop(context);
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(_backgroundColor == const Color(0xFFF5F5F5)
                                          ? Icons.dark_mode
                                          : Icons.light_mode),
                                      title: Text(_backgroundColor == const Color(0xFFF5F5F5)
                                          ? 'Dark Mode'
                                          : 'Light Mode'),
                                      onTap: () {
                                        _toggleDarkMode();
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      // Progress bar
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: LinearProgressIndicator(
                          value: (_currentPage + 1) / _pages.length,
                          backgroundColor: Colors.grey[600],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      // Page info
                      Text(
                        'Page ${_currentPage + 1} of ${_pages.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      // Navigation buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                            onPressed: _currentPage > 0
                                ? () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                            onPressed: _currentPage < _pages.length - 1
                                ? () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launchDownloadUrl(String? url, String format) async {
    if (url != null && await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open URL')),
      );
    }
  }
}