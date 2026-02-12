import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/interaction_service.dart';

class RecipeInteractionBar extends StatefulWidget {
  final int recipeId;

  const RecipeInteractionBar({
    super.key,
    required this.recipeId,
  });

  @override
  State<RecipeInteractionBar> createState() => _RecipeInteractionBarState();
}

class _RecipeInteractionBarState extends State<RecipeInteractionBar> {
  final _service = InteractionService();
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isInitialLoading = true;

  int _currentLikeCount = 0;
  int _currentSaveCount = 0;
  int _currentCommentCount = 0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() async {
    try {
      final liked = await _service.isLiked(widget.recipeId);
      final saved = await _service.isSaved(widget.recipeId);
      final lCount = await _service.getLikeCount(widget.recipeId);
      final sCount = await _service.getSaveCount(widget.recipeId);
      final cCount = await _service.getCommentCount(widget.recipeId);

      if (mounted) {
        setState(() {
          _isLiked = liked;
          _isSaved = saved;
          _currentLikeCount = lCount;
          _currentSaveCount = sCount;
          _currentCommentCount = cCount;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isInitialLoading = false);
    }
  }

  void _handleLike() async {
    final original = _isLiked;
    setState(() {
      _isLiked = !original;
      _isLiked ? _currentLikeCount++ : _currentLikeCount--;
    });
    try {
      await _service.toggleLike(widget.recipeId, original);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = original;
          _isLiked ? _currentLikeCount++ : _currentLikeCount--;
        });
      }
    }
  }

  void _handleSave() async {
    final original = _isSaved;
    setState(() {
      _isSaved = !original;
      _isSaved ? _currentSaveCount++ : _currentSaveCount--;
    });
    try {
      await _service.toggleSave(widget.recipeId, original);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaved = original;
          _isSaved ? _currentSaveCount++ : _currentSaveCount--;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Center(
        child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPill(Icons.favorite, _currentLikeCount, Colors.red, _isLiked, _handleLike),
        const SizedBox(width: 12),
        _buildPill(Icons.bookmark, _currentSaveCount, Colors.amber.shade800, _isSaved, _handleSave),
        const SizedBox(width: 12),
        _buildPill(Icons.chat_bubble_outline, _currentCommentCount, Colors.blue, false, () => _showComments(context)),
      ],
    );
  }

  Widget _buildPill(IconData icon, int count, Color color, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.1) : const Color(0xFFFFF9E6),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: active ? color : color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? (icon == Icons.favorite_border || icon == Icons.favorite ? Icons.favorite : Icons.bookmark) : icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text("$count", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF3CC),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => CommentSheet(
        recipeId: widget.recipeId,
        onCommentCountChanged: (newCount) {
          if (mounted) setState(() => _currentCommentCount = newCount);
        },
      ),
    );
  }
}

class CommentSheet extends StatefulWidget {
  final int recipeId;
  final Function(int) onCommentCountChanged;
  const CommentSheet({super.key, required this.recipeId, required this.onCommentCountChanged});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final _commentCtrl = TextEditingController();
  final _service = InteractionService();

  // New state for the internal message
  String? _statusMessage;

  void _showInternalMessage(String msg) {
    if (!mounted) return;
    setState(() => _statusMessage = msg);

    // Auto-hide the message after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _statusMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            // 1. Draggable indicator
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 10),

            // 2. Title
            const Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),

            // 3. THE INTERNAL POP-OUT MESSAGE
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _statusMessage == null ? 0 : 35,
              margin: EdgeInsets.only(top: _statusMessage == null ? 0 : 10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _statusMessage ?? "",
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 4. Comments List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _service.getCommentsStream(widget.recipeId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final comments = snapshot.data ?? [];

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) widget.onCommentCountChanged(comments.length);
                  });

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final bool isMe = comment['user_id'] == _service.currentUserId;

                      // LOGIC: If it's me, show "You", otherwise show the "user_name" fetched from DB
                      final String displayName = isMe ? "You" : (comment['user_name'] ?? "Chef");

                      String timeStr = "Just now";
                      if (comment['created_at'] != null) {
                        timeStr = DateFormat('jm').format(DateTime.parse(comment['created_at']).toLocal());
                      }

                      return ListTile(
                        leading: const CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.person, color: Colors.white)
                        ),
                        title: Text(
                            "$displayName • $timeStr",
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.orange : Colors.brown
                            )
                        ),
                        subtitle: Text(comment['content'] ?? ""),
                        trailing: isMe ? IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () async {
                            await _service.deleteComment(comment['id']);
                            _showInternalMessage("Comment deleted");
                          },
                        ) : null,
                      );
                    },
                  );
                },
              ),
            ),

            // 5. Input Field
            const SizedBox(height: 10),
            TextField(
              controller: _commentCtrl,
              decoration: InputDecoration(
                hintText: "Add a comment...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.orange),
                  onPressed: () async {
                    if (_commentCtrl.text.trim().isNotEmpty) {
                      final text = _commentCtrl.text.trim();
                      _commentCtrl.clear();
                      await _service.postComment(widget.recipeId, text);

                      // Trigger the internal message
                      _showInternalMessage("Comment added!");
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}