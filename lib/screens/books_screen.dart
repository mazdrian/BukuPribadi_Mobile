import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/book_provider.dart';
import '../models/book.dart';
import '../code/icon_helper.dart';
import '../code/app_theme.dart';
import 'create_book_screen.dart';
import 'book_detail_screen.dart';
import 'login_screen.dart';

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  Future<void> _navigateAndRefresh(
      BuildContext context, WidgetRef ref, Widget screen, String userId) async {
    await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (context) => screen),
    );
    ref.invalidate(userBooksProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginScreen();

        final booksAsync = ref.watch(userBooksProvider(user.id));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modern header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Books',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your financial records',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      _LogoutButton(ref: ref),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Content
                Expanded(
                  child: booksAsync.when(
                    data: (books) {
                      if (books.isEmpty) {
                        return _EmptyState(
                          onCreateBook: () => _navigateAndRefresh(
                            context,
                            ref,
                            CreateBookScreen(userId: user.id),
                            user.id,
                          ),
                        );
                      }
                      return _AnimatedBookList(
                        books: books,
                        onBookTap: (book) => _navigateAndRefresh(
                          context,
                          ref,
                          BookDetailScreen(book: book),
                          user.id,
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 3),
                    ),
                    error: (error, stack) => _ErrorState(error: error),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _navigateAndRefresh(
              context,
              ref,
              CreateBookScreen(userId: user.id),
              user.id,
            ),
            backgroundColor: AppColors.primary,
            elevation: 4,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 3)),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Error: ${error.toString()}')),
      ),
    );
  }
}

// ── Logout button ──────────────────────────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  final WidgetRef ref;
  const _LogoutButton({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Logout',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Logout',
                      style: TextStyle(color: AppColors.expense)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            try {
              await ref.read(authStateProvider.notifier).signOut();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: AppColors.expense,
                  ),
                );
              }
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.logout_rounded,
              color: AppColors.textSecondary, size: 22),
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateBook;
  const _EmptyState({required this.onCreateBook});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.menu_book_rounded,
                  size: 56, color: AppColors.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 28),
            Text(
              'No Books Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first book to start\ntracking your finances',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onCreateBook,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Book'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final Object error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.expense.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text('Error loading books',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(error.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── Animated book list with staggered entrance ─────────────────────────────
class _AnimatedBookList extends StatefulWidget {
  final List<Book> books;
  final void Function(Book) onBookTap;

  const _AnimatedBookList({required this.books, required this.onBookTap});

  @override
  State<_AnimatedBookList> createState() => _AnimatedBookListState();
}

class _AnimatedBookListState extends State<_AnimatedBookList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + widget.books.length * 100),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: widget.books.length,
      itemBuilder: (context, index) {
        final begin = (index * 0.15).clamp(0.0, 0.8);
        final end = (begin + 0.4).clamp(0.0, 1.0);

        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Interval(begin, end, curve: Curves.easeOutCubic),
        ));

        final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(begin, end, curve: Curves.easeOut),
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: _BookCard(
              book: widget.books[index],
              onTap: () => widget.onBookTap(widget.books[index]),
            ),
          ),
        );
      },
    );
  }
}

// ── Modern book card ───────────────────────────────────────────────────────
class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const _BookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bookColor = Color(int.parse('FF${book.color}', radix: 16));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: bookColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Icon(
                      IconHelper.getIcon(book.icon),
                      size: 28,
                      color: bookColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (book.description != null &&
                          book.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            book.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 16, color: AppColors.textSecondary.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
