// chat_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

// --- Data Model for a Chat Message ---
enum MessageSender { user, agent, system }

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final String? agentName;
  Map<String, dynamic>? tradeProposalDetails;
  String? tradeProposalState;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.agentName,
    this.tradeProposalDetails,
    this.tradeProposalState,
  });
}

// --- Example Prompts ---
const List<String> _examplePrompts = [
  "What's the current trend for EURUSD?",
  "Scalp trade idea for GBP/JPY right now?",
  "Day trade analysis for XAUUSD.",
  "Any swing trade opportunities on AUD/USD?",
  "Long term position for BTC/USD based on weekly chart.",
  "What are the key support and resistance levels for EUR/USD on H1?",
  "Fetch 50 bars of M15 data for USD/CAD and show RSI.",
  "Analyze the current spread for EURGBP.",
  "What's the MACD crossover status on H4 for NZD/USD?",
  "RSI is over 70 on M5 for EUR/JPY, what should I do?",
  "EMA 12 is below EMA 26 on D1 for GBPUSD, is this a sell signal for position trader?",
  "Give me a scalping signal for EUR/USD based on M1 EMAs (5,10) and RSI (7).",
  "Suggest a day trade for GOLD with SL and TP based on H1 chart.",
  "What does the Swing Trader think about USD/CHF D1 chart?",
  "Position Trader outlook for EUR/AUD on W1 chart.",
  "Is AUD/JPY suitable for scalping now?",
  "Day trade EUR/USD: Analyze current H1 conditions.",
  "Swing trade setup for GBP/CAD using daily EMAs and MACD.",
  "Position trade: GBP/USD analysis on weekly chart with fundamental context if possible.",
  "Current market sentiment for oil (WTIUSD or XTIUSD)?",
  "Analyze volatility for USD/JPY for a potential scalp.",
  "What are the active trading hours for a day trader focusing on London session for EUR/GBP?",
  "Show me the H4 chart for AUD/NZD with EMA 20 and EMA 50.",
  "Any news affecting CAD pairs today?",
  "What's the risk level for a swing trade on EUR/USD right now?"
];


// --- Chat Page Widget ---
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final String _fastApiBaseUrl = "http://10.0.2.2:8000";

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final String userId = DateTime.now().millisecondsSinceEpoch.toString() + '_user';
    final userMessage = ChatMessage(
      id: userId,
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, userMessage);
      _textController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    // Removed explicit "Agent is thinking..." message.
    // _isLoading = true will now control a global indicator.

    try {
      final response = await http.post(
        Uri.parse('$_fastApiBaseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': text}),
      ).timeout(const Duration(seconds: 60));

      // No need to manually remove "thinking" message from list anymore

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String agentRationale = responseData['response'];
        final String? agentUsed = responseData['agent_used'];
        final Map<String, dynamic>? tradeProposal = responseData['trade_proposal'];

        final agentMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_agent',
          text: agentRationale,
          sender: MessageSender.agent,
          timestamp: DateTime.now(),
          agentName: agentUsed,
          tradeProposalDetails: tradeProposal,
          tradeProposalState: tradeProposal != null ? "pending" : null,
        );
        setState(() {
          _messages.insert(0, agentMessage);
        });
      } else {
        _addErrorMessage("Error from agent: ${response.statusCode} ${response.reasonPhrase}");
      }
    } catch (e) {
      // No need to manually remove "thinking" message from list anymore
      print("Error sending message: $e");
      _addErrorMessage("Failed to connect to agent. Please check connection. ($e)");
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _addErrorMessage(String errorText) {
    final errorMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString() + '_error',
      text: errorText,
      sender: MessageSender.system,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.insert(0, errorMessage);
    });
  }

  Future<void> _confirmTrade(ChatMessage agentMessage) async {
    if (agentMessage.tradeProposalDetails == null) return;
    final payload = {
        "agent_id": agentMessage.tradeProposalDetails!['agent_id'] ?? agentMessage.agentName ?? "UnknownAgent",
        "currency_pair": agentMessage.tradeProposalDetails!['pair'],
        "order_side": agentMessage.tradeProposalDetails!['action'],
        "entry_price": agentMessage.tradeProposalDetails!['entry_price'],
        "stop_loss": agentMessage.tradeProposalDetails!['stop_loss'],
        "take_profit": agentMessage.tradeProposalDetails!['take_profit'],
        "volume": 0.01
    };
    final String tradeInfo = "${payload['order_side']} ${payload['currency_pair']} @ ${payload['entry_price']}";

    try {
      final response = await http.post(
        Uri.parse('$_fastApiBaseUrl/webhook/trade'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() { agentMessage.tradeProposalState = "confirmed"; });
        _addSystemMessage("Trade for $tradeInfo confirmed (Simulated: ${responseData['message']})");
      } else {
        setState(() { agentMessage.tradeProposalState = "error"; });
        _addErrorMessage("Failed to confirm trade for $tradeInfo: ${response.statusCode} ${response.reasonPhrase}");
      }
    } catch (e) {
      setState(() { agentMessage.tradeProposalState = "error"; });
      _addErrorMessage("Error confirming trade for $tradeInfo: $e");
    }
    _scrollToBottom();
  }

  void _declineTrade(ChatMessage agentMessage) {
    setState(() { agentMessage.tradeProposalState = "declined";});
    _addSystemMessage("Trade proposal declined by user.");
    _scrollToBottom();
  }

  void _addSystemMessage(String text) {
    final systemMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString() + '_system',
      text: text, sender: MessageSender.system, timestamp: DateTime.now(),
    );
    setState(() { _messages.insert(0, systemMessage); });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _showExamplePromptsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[850], // Dark theme for bottom sheet
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5, // Half screen height
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical:8.0, horizontal: 16.0),
                child: Text(
                  "Example Prompts",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(color: Colors.grey[700], height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: _examplePrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = _examplePrompts[index];
                    return ListTile(
                      title: Text(prompt, style: TextStyle(color: Colors.grey[200])),
                      dense: true,
                      onTap: () {
                        _textController.text = prompt;
                        Navigator.pop(context); // Dismiss bottom sheet
                      },
                      leading: Icon(Icons.chat_bubble_outline, color: Colors.redAccent[100], size: 20),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('AI Trading Agents'),
        backgroundColor: Colors.grey[850],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline, color: Colors.redAccent),
            tooltip: "Example Prompts",
            onPressed: _showExamplePromptsSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatMessageWidget(
                  message: message,
                  onConfirmTrade: () => _confirmTrade(message),
                  onDeclineTrade: () => _declineTrade(message),
                );
              },
            ),
          ),
          if (_isLoading)
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 8.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   SizedBox(
                     width: 20, height: 20,
                     child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent[100]!), strokeWidth: 2.0)
                   ),
                   const SizedBox(width: 10),
                   Text("Agent is thinking...", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                 ],
               ),
             ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(color: Colors.grey[850]),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Ask your trading agent...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25.0), borderSide: BorderSide(color: Colors.redAccent, width: 1.5)),
                ),
                onSubmitted: _isLoading ? null : (text) => _sendMessage(text),
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.redAccent),
              onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
              splashRadius: 24.0,
              tooltip: 'Send message',
            ),
          ],
        ),
      ),
    );
  }
}

// --- Chat Message Widget ---
class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onConfirmTrade;
  final VoidCallback? onDeclineTrade;

  const ChatMessageWidget({
    super.key,
    required this.message,
    this.onConfirmTrade,
    this.onDeclineTrade,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.sender == MessageSender.user;
    final bool isSystem = message.sender == MessageSender.system;

    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final Color bubbleColor;
    final Color textColor;

    if (isUser) {
      bubbleColor = Colors.redAccent[400]!;
      textColor = Colors.white;
    } else if (isSystem) {
      bubbleColor = Colors.blueGrey[700]!;
      textColor = Colors.white70;
    } else { // Agent
      bubbleColor = Colors.grey[800]!;
      textColor = Colors.white;
    }

    return Column(
      crossAxisAlignment: align,
      children: [
        if (message.agentName != null && !isUser && !isSystem) // Don't show agent name for system thinking messages
          Padding(
            padding: const EdgeInsets.only(left: 10.0, bottom: 2.0),
            child: Text(
              message.agentName == "System" ? "" : message.agentName!, // Hide "System" as agent name here
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16.0),
              topRight: const Radius.circular(16.0),
              bottomLeft: isUser ? const Radius.circular(16.0) : const Radius.circular(0.0),
              bottomRight: isUser ? const Radius.circular(0.0) : const Radius.circular(16.0),
            ),
          ),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: isUser || isSystem
              ? Text(message.text, style: TextStyle(color: textColor, fontSize: 15))
              : MarkdownBody(
                  data: message.text,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 15),
                     a: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline),
                  ),
                ),
        ),
        if (message.tradeProposalDetails != null && message.sender == MessageSender.agent)
          _buildTradeProposalCard(context),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
            style: TextStyle(color: Colors.grey[400], fontSize: 10.0),
          ),
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }

  Widget _buildTradeProposalCard(BuildContext context) {
    final details = message.tradeProposalDetails!;
    final bool isPending = message.tradeProposalState == "pending";
    final bool isConfirmed = message.tradeProposalState == "confirmed";
    final bool isDeclined = message.tradeProposalState == "declined";
    final bool isError = message.tradeProposalState == "error";

    Color cardColor = Colors.blueGrey[800]!;
    String statusText = "Proposed Trade";
    if (isConfirmed) {
      cardColor = Colors.green[800]!;
      statusText = "Trade Confirmed";
    } else if (isDeclined) {
      cardColor = Colors.red[900]!;
      statusText = "Trade Declined";
    } else if (isError) {
      cardColor = Colors.orange[900]!;
      statusText = "Trade Confirmation Error";
    }

    return Container(
      margin: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 0, right: isUser ? 0 : (MediaQuery.of(context).size.width * 0.25 - 14).clamp(0.0, double.infinity)),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blueGrey[700]!)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text("Action: ${details['action']}", style: const TextStyle(color: Colors.white70)),
          Text("Pair: ${details['pair']}", style: const TextStyle(color: Colors.white70)),
          Text("Entry: ${details['entry_price']}", style: const TextStyle(color: Colors.white70)),
          if (details['stop_loss'] != null)
            Text("SL: ${details['stop_loss']}", style: const TextStyle(color: Colors.white70)),
          if (details['take_profit'] != null)
            Text("TP: ${details['take_profit']}", style: const TextStyle(color: Colors.white70)),
          if (details['agent_id'] != null)
             Text("Agent ID: ${details['agent_id']}", style: const TextStyle(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 10),
          if (isPending)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDeclineTrade,
                  child: const Text("Decline", style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onConfirmTrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text("Confirm Trade", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
