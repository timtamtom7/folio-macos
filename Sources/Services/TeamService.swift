import Foundation

// MARK: - Team Model

struct Team: Identifiable, Codable {
    let id: UUID
    var name: String
    let ownerId: String
    var inviteCode: String?
    let createdAt: Date
    
    init(id: UUID = UUID(), name: String, ownerId: String, inviteCode: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.ownerId = ownerId
        self.inviteCode = inviteCode
        self.createdAt = createdAt
    }
}

struct TeamMember: Codable {
    let teamId: UUID
    let userId: String
    var role: Role
    
    enum Role: String, Codable {
        case owner
        case admin
        case member
    }
}

struct TeamFeed: Codable {
    let teamId: UUID
    let feedId: UUID
    let addedBy: String
    let addedAt: Date
}

// MARK: - Team Service

final class TeamService {
    static let shared = TeamService()
    
    private let teamsKey = "teams"
    private let teamMembersKey = "team_members"
    private let teamFeedsKey = "team_feeds"
    
    private init() {}
    
    // MARK: - Team Management
    
    func getAllTeams() -> [Team] {
        guard let data = UserDefaults.standard.data(forKey: teamsKey),
              let teams = try? JSONDecoder().decode([Team].self, from: data) else {
            return []
        }
        return teams
    }
    
    func createTeam(name: String, ownerId: String) -> Team {
        let team = Team(name: name, ownerId: ownerId, inviteCode: generateInviteCode())
        var teams = getAllTeams()
        teams.append(team)
        saveTeams(teams)
        
        // Add owner as member
        addMember(toTeam: team.id, userId: ownerId, role: .owner)
        
        return team
    }
    
    func deleteTeam(id: UUID) {
        var teams = getAllTeams()
        teams.removeAll { $0.id == id }
        saveTeams(teams)
        
        // Also remove members and feeds
        var members = getAllMembers()
        members.removeAll { $0.teamId == id }
        saveMembers(members)
        
        var feeds = getAllTeamFeeds()
        feeds.removeAll { $0.teamId == id }
        saveTeamFeeds(feeds)
    }
    
    private func saveTeams(_ teams: [Team]) {
        if let data = try? JSONEncoder().encode(teams) {
            UserDefaults.standard.set(data, forKey: teamsKey)
        }
    }
    
    // MARK: - Team Members
    
    func getMembers(ofTeam teamId: UUID) -> [TeamMember] {
        return getAllMembers().filter { $0.teamId == teamId }
    }
    
    func addMember(toTeam teamId: UUID, userId: String, role: TeamMember.Role) {
        var members = getAllMembers()
        members.append(TeamMember(teamId: teamId, userId: userId, role: role))
        saveMembers(members)
    }
    
    func removeMember(fromTeam teamId: UUID, userId: String) {
        var members = getAllMembers()
        members.removeAll { $0.teamId == teamId && $0.userId == userId }
        saveMembers(members)
    }
    
    private func getAllMembers() -> [TeamMember] {
        guard let data = UserDefaults.standard.data(forKey: teamMembersKey),
              let members = try? JSONDecoder().decode([TeamMember].self, from: data) else {
            return []
        }
        return members
    }
    
    private func saveMembers(_ members: [TeamMember]) {
        if let data = try? JSONEncoder().encode(members) {
            UserDefaults.standard.set(data, forKey: teamMembersKey)
        }
    }
    
    // MARK: - Team Feeds
    
    func getFeeds(ofTeam teamId: UUID) -> [UUID] {
        return getAllTeamFeeds().filter { $0.teamId == teamId }.map { $0.feedId }
    }
    
    func addFeed(toTeam teamId: UUID, feedId: UUID, addedBy: String) {
        var feeds = getAllTeamFeeds()
        if !feeds.contains(where: { $0.teamId == teamId && $0.feedId == feedId }) {
            feeds.append(TeamFeed(teamId: teamId, feedId: feedId, addedBy: addedBy, addedAt: Date()))
            saveTeamFeeds(feeds)
        }
    }
    
    func removeFeed(fromTeam teamId: UUID, feedId: UUID) {
        var feeds = getAllTeamFeeds()
        feeds.removeAll { $0.teamId == teamId && $0.feedId == feedId }
        saveTeamFeeds(feeds)
    }
    
    private func getAllTeamFeeds() -> [TeamFeed] {
        guard let data = UserDefaults.standard.data(forKey: teamFeedsKey),
              let feeds = try? JSONDecoder().decode([TeamFeed].self, from: data) else {
            return []
        }
        return feeds
    }
    
    private func saveTeamFeeds(_ feeds: [TeamFeed]) {
        if let data = try? JSONEncoder().encode(feeds) {
            UserDefaults.standard.set(data, forKey: teamFeedsKey)
        }
    }
    
    // MARK: - Invite Code
    
    private func generateInviteCode() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
    
    func joinTeam(withCode code: String, userId: String) -> Team? {
        let teams = getAllTeams()
        if let team = teams.first(where: { $0.inviteCode == code }) {
            addMember(toTeam: team.id, userId: userId, role: .member)
            return team
        }
        return nil
    }
}
