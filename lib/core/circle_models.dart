enum MemberWakeStatus { awake, notYetAwake, unreachable }

enum WakeEventStatus { active, completed, cancelled }

class CircleMember {
	final String id;
	final String displayName;
	final DateTime joinedAt;
	final MemberWakeStatus wakeStatus;

	const CircleMember({
		required this.id,
		required this.displayName,
		required this.joinedAt,
		required this.wakeStatus,
	});

	CircleMember copyWith({
		String? id,
		String? displayName,
		DateTime? joinedAt,
		MemberWakeStatus? wakeStatus,
	}) {
		return CircleMember(
			id: id ?? this.id,
			displayName: displayName ?? this.displayName,
			joinedAt: joinedAt ?? this.joinedAt,
			wakeStatus: wakeStatus ?? this.wakeStatus,
		);
	}

	Map<String, dynamic> toMap() {
		return {
			'id': id,
			'displayName': displayName,
			'joinedAt': joinedAt.toIso8601String(),
			'wakeStatus': wakeStatus.name,
		};
	}

	factory CircleMember.fromMap(Map<String, dynamic> map) {
		return CircleMember(
			id: map['id'] as String,
			displayName: map['displayName'] as String,
			joinedAt: DateTime.parse(map['joinedAt'] as String),
			wakeStatus: MemberWakeStatus.values.firstWhere(
				(value) => value.name == map['wakeStatus'],
				orElse: () => MemberWakeStatus.notYetAwake,
			),
		);
	}
}

class WakeCircle {
	final String circleId;
	final String hostPeerId;
	final DateTime createdAt;

	const WakeCircle({
		required this.circleId,
		required this.hostPeerId,
		required this.createdAt,
	});

	WakeCircle copyWith({
		String? circleId,
		String? hostPeerId,
		DateTime? createdAt,
	}) {
		return WakeCircle(
			circleId: circleId ?? this.circleId,
			hostPeerId: hostPeerId ?? this.hostPeerId,
			createdAt: createdAt ?? this.createdAt,
		);
	}

	Map<String, dynamic> toMap() {
		return {
			'circleId': circleId,
			'hostPeerId': hostPeerId,
			'createdAt': createdAt.toIso8601String(),
		};
	}

	factory WakeCircle.fromMap(Map<String, dynamic> map) {
		return WakeCircle(
			circleId: map['circleId'] as String,
			hostPeerId: map['hostPeerId'] as String,
			createdAt: DateTime.parse(map['createdAt'] as String),
		);
	}
}

class WakeEvent {
	final String id;
	final String circleId;
	final String initiatedByPeerId;
	final DateTime startedAt;
	final WakeEventStatus status;

	const WakeEvent({
		required this.id,
		required this.circleId,
		required this.initiatedByPeerId,
		required this.startedAt,
		required this.status,
	});

	WakeEvent copyWith({
		String? id,
		String? circleId,
		String? initiatedByPeerId,
		DateTime? startedAt,
		WakeEventStatus? status,
	}) {
		return WakeEvent(
			id: id ?? this.id,
			circleId: circleId ?? this.circleId,
			initiatedByPeerId: initiatedByPeerId ?? this.initiatedByPeerId,
			startedAt: startedAt ?? this.startedAt,
			status: status ?? this.status,
		);
	}

	Map<String, dynamic> toMap() {
		return {
			'id': id,
			'circleId': circleId,
			'initiatedByPeerId': initiatedByPeerId,
			'startedAt': startedAt.toIso8601String(),
			'status': status.name,
		};
	}

	factory WakeEvent.fromMap(Map<String, dynamic> map) {
		return WakeEvent(
			id: map['id'] as String,
			circleId: map['circleId'] as String,
			initiatedByPeerId: map['initiatedByPeerId'] as String,
			startedAt: DateTime.parse(map['startedAt'] as String),
			status: WakeEventStatus.values.firstWhere(
				(value) => value.name == map['status'],
				orElse: () => WakeEventStatus.active,
			),
		);
	}
}

/// A single persisted record of a member's wake outcome for a given day.
class WakeHistoryRecord {
	final String memberId;
	final String displayName;

	/// The calendar date this record belongs to (time normalized to midnight UTC).
	final DateTime date;

	/// Whether the member completed the wake challenge.
	final bool completed;

	/// When the member confirmed they were awake (null if not completed).
	final DateTime? completionTime;

	const WakeHistoryRecord({
		required this.memberId,
		required this.displayName,
		required this.date,
		required this.completed,
		this.completionTime,
	});

	Map<String, dynamic> toMap() {
		return {
			'memberId': memberId,
			'displayName': displayName,
			'date': date.toIso8601String(),
			'completed': completed,
			'completionTime': completionTime?.toIso8601String(),
		};
	}

	factory WakeHistoryRecord.fromMap(Map<String, dynamic> map) {
		return WakeHistoryRecord(
			memberId: map['memberId'] as String,
			displayName: map['displayName'] as String,
			date: DateTime.parse(map['date'] as String),
			completed: map['completed'] as bool,
			completionTime: map['completionTime'] != null
					? DateTime.parse(map['completionTime'] as String)
					: null,
		);
	}
}
