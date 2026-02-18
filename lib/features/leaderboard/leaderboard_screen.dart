import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/permissions.dart';
import 'join_squad_view_model.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JoinSquadViewModel(),
      child: Builder(
        builder: (context) {
          final viewModel = context.watch<JoinSquadViewModel>();

          return Scaffold(
            backgroundColor: const Color(0xFF060B28),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF121936),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () {},
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Join a Squad',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 52),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(42),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF0A0F1E), Color(0xFF04060E)],
                          ),
                          border: Border.all(color: const Color(0xFF20305A)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x5500F5A0),
                              blurRadius: 40,
                              spreadRadius: -20,
                              offset: Offset(0, 26),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            const Positioned(
                              top: 8,
                              left: 8,
                              child: _ScannerCorner(isTop: true, isLeft: true),
                            ),
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: _ScannerCorner(isTop: true, isLeft: false),
                            ),
                            const Positioned(
                              bottom: 8,
                              left: 8,
                              child: _ScannerCorner(isTop: false, isLeft: true),
                            ),
                            const Positioned(
                              bottom: 8,
                              right: 8,
                              child: _ScannerCorner(
                                isTop: false,
                                isLeft: false,
                              ),
                            ),
                            Column(
                              children: [
                                const Spacer(flex: 2),
                                Container(
                                  width: 225,
                                  height: 225,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0xFF303744),
                                        Color(0xFF0A0F1C),
                                      ],
                                    ),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.camera_alt_outlined,
                                      color: Colors.white54,
                                      size: 96,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 36),
                                Container(
                                  width: 260,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(40),
                                    color: const Color(0xFF111822),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.qr_code_scanner,
                                        size: 20,
                                        color: Color(0xFF00F5A0),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        viewModel.statusMessage,
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF00F5A0),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                            const Positioned(
                              left: 12,
                              right: 12,
                              top: 230,
                              child: _ScanBeam(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        "Point your camera at a friend's QR code\nto join their Suhoor squad.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFA4ABBE),
                          fontSize: 18,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (viewModel.members.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Squad members: ${viewModel.members.map((member) => member.displayName).join(', ')}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFA4ABBE),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    SizedBox(
                      height: 72,
                      child: ElevatedButton.icon(
                        onPressed: viewModel.isScanning
                            ? null
                            : () async {
                                final joinSquadViewModel = context
                                    .read<JoinSquadViewModel>();
                                final messenger = ScaffoldMessenger.of(context);

                                final hasPermissions =
                                    await PermissionManager.requestRequiredPermissions(
                                      context,
                                    );

                                if (!hasPermissions) {
                                  return;
                                }

                                if (!context.mounted) {
                                  return;
                                }

                                final qrPayload = await _showQrPayloadDialog(
                                  context,
                                );
                                if (qrPayload == null ||
                                    qrPayload.trim().isEmpty) {
                                  return;
                                }

                                await joinSquadViewModel.scanToJoin(qrPayload);

                                if (context.mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        joinSquadViewModel.statusMessage,
                                      ),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.qr_code_2, size: 28),
                        label: Text(
                          'Scan to Join',
                          style: GoogleFonts.poppins(
                            fontSize: 40 / 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xFF03121A),
                          backgroundColor: const Color(0xFF00F58D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 72,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final joinSquadViewModel = context
                              .read<JoinSquadViewModel>();
                          final messenger = ScaffoldMessenger.of(context);

                          final memberName = await _showAddMemberDialog(
                            context,
                          );
                          if (memberName == null || memberName.trim().isEmpty) {
                            return;
                          }

                          await joinSquadViewModel.addSquadMemberManually(
                            memberName,
                          );

                          if (context.mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('$memberName added to squad'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.person_add_alt_1,
                          size: 28,
                          color: Color(0xFF00F58D),
                        ),
                        label: Text(
                          'Add Squad Members',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF00F58D),
                            fontSize: 39 / 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF00A16F),
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _showAddMemberDialog(BuildContext context) async {
    final textController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Squad Member'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter member name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(textController.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showQrPayloadDialog(BuildContext context) async {
    final textController = TextEditingController(
      text: JoinSquadViewModel.buildSampleQrPayload(),
    );

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Scan QR Payload'),
          content: TextField(
            controller: textController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Paste QR payload JSON',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(textController.text.trim()),
              child: const Text('Join'),
            ),
          ],
        );
      },
    );
  }
}

class _ScanBeam extends StatelessWidget {
  const _ScanBeam();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0x0000F58D), Color(0xFF00F58D), Color(0x0000F58D)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x9000F58D), blurRadius: 16, spreadRadius: 2),
        ],
      ),
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _ScannerCorner({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    final BorderSide border = const BorderSide(
      color: Color(0xFF00F58D),
      width: 6,
      strokeAlign: BorderSide.strokeAlignOutside,
    );

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(color: Color(0xAA00F58D), blurRadius: 26, spreadRadius: -8),
        ],
        border: Border(
          top: isTop ? border : BorderSide.none,
          left: isLeft ? border : BorderSide.none,
          right: isLeft ? BorderSide.none : border,
          bottom: isTop ? BorderSide.none : border,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isTop && isLeft ? 30 : 0),
          topRight: Radius.circular(isTop && !isLeft ? 30 : 0),
          bottomLeft: Radius.circular(!isTop && isLeft ? 30 : 0),
          bottomRight: Radius.circular(!isTop && !isLeft ? 30 : 0),
        ),
      ),
    );
  }
}
