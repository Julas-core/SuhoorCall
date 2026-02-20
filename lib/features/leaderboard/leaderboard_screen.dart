import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/permissions.dart';
import 'join_squad_view_model.dart';
import 'qr_scan_screen.dart';

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
                    if (viewModel.activeCircleId != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutBack,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: Text(
                            'Circle ID: ${viewModel.activeCircleId} • Members: ${viewModel.joinedMembersCount}',
                            key: ValueKey<int>(viewModel.joinedMembersCount),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFA4ABBE),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      height: 72,
                      child: ElevatedButton.icon(
                        onPressed: viewModel.isGeneratingQr
                            ? null
                            : () async {
                                final joinSquadViewModel = context
                                    .read<JoinSquadViewModel>();
                                final messenger = ScaffoldMessenger.of(context);

                                final invitationPayload =
                                    await joinSquadViewModel
                                        .createCircleAndBuildInvitation();

                                if (!context.mounted) {
                                  return;
                                }

                                await _showHostQrDialog(
                                  context,
                                  viewModel: joinSquadViewModel,
                                  invitationPayload: invitationPayload,
                                );

                                if (context.mounted) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Circle QR ready to share'),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.qr_code, size: 28),
                        label: Text(
                          'Create Circle',
                          style: GoogleFonts.poppins(
                            fontSize: 40 / 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFF20305A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (viewModel.members.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111822),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Confirmation Tracking',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Awake: ${viewModel.awakeCount} • Not yet awake: ${viewModel.notYetAwakeCount} • Unreachable: ${viewModel.unreachableCount}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFA4ABBE),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...viewModel.members.map(
                                (member) => _MemberStatusRow(
                                  member: member,
                                  onStatusSelected: (status) async {
                                    await context
                                        .read<JoinSquadViewModel>()
                                        .setMemberWakeStatus(member.id, status);
                                  },
                                ),
                              ),
                            ],
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

                                final hasCameraPermission =
                                    await PermissionManager.requestCameraPermission(
                                      context,
                                    );

                                if (!hasCameraPermission) {
                                  return;
                                }

                                if (!context.mounted) {
                                  return;
                                }

                                final qrPayload = await Navigator.of(context)
                                    .push<String>(
                                      MaterialPageRoute<String>(
                                        builder: (_) => const QrScanScreen(),
                                      ),
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

  Future<void> _showHostQrDialog(
    BuildContext context, {
    required JoinSquadViewModel viewModel,
    required String invitationPayload,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return ChangeNotifierProvider<JoinSquadViewModel>.value(
          value: viewModel,
          child: Consumer<JoinSquadViewModel>(
            builder: (context, liveViewModel, _) {
              final circleId =
                  liveViewModel.hostCircleId ?? liveViewModel.activeCircleId;
              final joinedMembersCount = liveViewModel.joinedMembersCount;

              return AlertDialog(
                backgroundColor: const Color(0xFF111822),
                title: Text(
                  'Your Circle QR',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: invitationPayload,
                          size: 220,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF0F3460),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF0F3460),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Have your friends scan this code to join your circle.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFA4ABBE),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutBack,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Text(
                          circleId == null
                              ? 'Members joined: $joinedMembersCount'
                              : 'Circle ID: $circleId\nMembers joined: $joinedMembersCount',
                          key: ValueKey<int>(joinedMembersCount),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF00F5A0),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: invitationPayload),
                      );

                      if (!dialogContext.mounted) {
                        return;
                      }

                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Copy'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          ),
        );
      },
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
}

class _MemberStatusRow extends StatelessWidget {
  final SquadMember member;
  final ValueChanged<MemberWakeStatus> onStatusSelected;

  const _MemberStatusRow({
    required this.member,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = _badgeData(member.wakeStatus);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              member.displayName,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withOpacity(0.7)),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<MemberWakeStatus>(
            icon: const Icon(Icons.more_horiz, color: Colors.white70, size: 20),
            onSelected: onStatusSelected,
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: MemberWakeStatus.awake,
                  child: Text('Mark Awake'),
                ),
                PopupMenuItem(
                  value: MemberWakeStatus.notYetAwake,
                  child: Text('Mark Not yet awake'),
                ),
                PopupMenuItem(
                  value: MemberWakeStatus.unreachable,
                  child: Text('Mark Unreachable'),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  (String, Color) _badgeData(MemberWakeStatus status) {
    switch (status) {
      case MemberWakeStatus.awake:
        return ('Awake', const Color(0xFF00F58D));
      case MemberWakeStatus.notYetAwake:
        return ('Not yet awake', const Color(0xFFFFC857));
      case MemberWakeStatus.unreachable:
        return ('Unreachable', const Color(0xFFE94560));
    }
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
