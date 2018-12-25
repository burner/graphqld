module testdata;

import std.array : array, back;
import std.algorithm : map;

import types;

const schemaString = `
schema {
	query: Query
	mutation: Mutation
	subscription: Subscription
}

// The query type, represents all of the entry points into our object graph
type Query {
	hero(episode: Episode): Character
	reviews(episode: Episode!): [Review]
	search(text: String): [SearchResult]
	character(id: ID!): Character
	droid(id: ID!): Droid
	human(id: ID!): Human
	starship(id: ID!): Starship
}
// The mutation type, represents all updates we can make to our data
type Mutation {
	createReview(episode: Episode, review: ReviewInput!): Review
}
// The subscription type, represents all subscriptions we can make to our data
type Subscription {
	reviewAdded(episode: Episode): Review
}
`;

// The episodes in the Star Wars trilogy
enum Episode {
	// Star Wars Episode IV: A New Hope, released in 1977.
	NEWHOPE,

	// Star Wars Episode V: The Empire Strikes Back, released in 1980.
	EMPIRE,

	// Star Wars Episode VI: Return of the Jedi, released in 1983.
	JEDI
}

// A character from the Star Wars universe
abstract class Character {
	// The ID of the character
	@GraphQLType(NotNull.yes)
	long id;

	// The name of the character
	@GraphQLType(NotNull.yes)
	string name;

	// The friends of the character, or an empty list if they have none
	long[] friends;

	// The friends of the character exposed as a connection with edges
	@GraphQLType(NotNull.yes)
	FriendsConnection friendsConnection(int first, long after);

	// The movies this character appears in
	@GraphQLType(NotNull.yes)
	string[] appearsIn;
}

// Units of height
enum LengthUnit {
	// The standard unit around the world
	METER,

	// Primarily used in the United States
	FOOT
}

// A humanoid creature from the Star Wars universe
class Human : Character {
	// The home planet of the human, or null if unknown
	string homePlanet;

	// Height in the preferred unit, default is meters
	float height;

	// Mass in kilograms, or null if unknown
	float mass;

	// A list of starships this person has piloted, or an empty list if none
	long[] starships;
}

// An autonomous mechanical character in the Star Wars universe
class Droid : Character {
	// This droid's primary function
	string primaryFunction;
}

// A connection object for a character's friends
class FriendsConnection {
	// The total number of friends
	int totalCount;

	// The edges for each of the character's friends.
	FriendsEdge[] edges;

	// A list of the friends, as a convenience when edges are not needed.
	Character[] friends;

	// Information for paginating this connection
	@GraphQLType(NotNull.yes)
	PageInfo pageInfo;
}

// An edge object for a character's friends
class FriendsEdge {
	// A cursor used for pagination
	@GraphQLType(NotNull.yes)
	long cursor;

	// The character represented by this friendship edge
	Character node;
}

// Information for paginating this connection
class PageInfo {
	long startCursor;
	long endCursor;
	@GraphQLType(NotNull.yes)
	bool hasNextPage;
}

// Represents a review for a movie
class Review {
	// The movie
	Episode episode;

	// The number of stars this review gave, 1-5
	@GraphQLType(NotNull.yes)
	int stars;

	// Comment about the movie
	string commentary;
}

// The input object sent when someone is creating a new review
struct ReviewInput {
	// 0-5 stars
	@GraphQLType(NotNull.yes)
	int stars;

	// Comment about the movie, optional
	string commentary;

	// Favorite color, optional
	ColorInput favoriteColor;
}

// The input object sent when passing in a color
struct ColorInput {
	@GraphQLType(NotNull.yes)
	int red;

	@GraphQLType(NotNull.yes)
	int green;

	@GraphQLType(NotNull.yes)
	int blue;
}

class Starship {
	// The ID of the starship
	@GraphQLType(NotNull.yes)
	long id;

	// The name of the starship
	@GraphQLType(NotNull.yes)
	string name;

	// Length of the starship, along the longest axis
	float length;

	@GraphQLType(NotNull.yes)
	float[][] coordinates;
}

union SearchResult {
	Human human;
	Droid droid;
	Starship starship;
}

Human[] getHumans() {
	Human[] ret;
	ret ~= new Human;
	ret.back.id = 1000;
	ret.back.name = "Luke Skywalker";
	ret.back.friends = [ 1002, 1003, 2000, 2001 ];
	ret.back.appearsIn = [ "NEWHOPE", "EMPIRE", "JEDI" ];
	ret.back.homePlanet = "Tatooine";
	ret.back.height = 1.72;
	ret.back.mass = 77;
	ret.back.starships = [ 3001, 3003 ];

	ret ~= new Human;
	ret.back.id = 1001;
	ret.back.name = "Darth Vader";
	ret.back.friends = [ 1004 ];
	ret.back.appearsIn = [ "NEWHOPE", "EMPIRE", "JEDI" ];
	ret.back.homePlanet = "Tatooine";
	ret.back.height = 2.02;
	ret.back.mass = 136;
	ret.back.starships = [ 3002 ];

	ret ~= new Human;
	ret.back.id = 1002;
	ret.back.name = "Han Solo";
	ret.back.friends = [ 1000, 1003, 2001 ];
	ret.back.appearsIn = [ "NEWHOPE", "EMPIRE", "JEDI" ];
	ret.back.height = 1.8;
	ret.back.mass = 80;
	ret.back.starships = [ 3000, 3003 ];

	ret ~= new Human;
	ret.back.id = 1003;
	ret.back.name = "Leia Organa";
	ret.back.friends = [ 1000, 1002, 2000, 2001 ];
	ret.back.appearsIn = [ "NEWHOPE", "EMPIRE", "JEDI" ];
	ret.back.homePlanet = "Alderaan";
	ret.back.height = 1.5;
	ret.back.mass = 49;
	ret.back.starships = [];

	ret ~= new Human;
	ret.back.id = 1004;
	ret.back.name = "Wilhuff Tarkin";
	ret.back.friends = [ 1001 ];
	ret.back.appearsIn = [ "NEWHOPE" ];
	ret.back.height = 1.8;
	ret.back.starships = [];

	return ret;
}

Droid[] getDroids() {
	Droid[] ret;

	ret ~= new Droid;
	ret.back.id = 2000;
	ret.back.name = "C-3PO";
	ret.back.friends = [ 1000, 1002, 1003, 2001 ];
	ret.back.appearsIn = [ "NEWHOPE", "EMPIRE", "JEDI" ];
	ret.back.primaryFunction = "Protocol";

	ret ~= new Droid;
	ret.back.id = 2001;
	ret.back.name = "R2-D2";
	ret.back.friends = [ 1000, 1002, 1003 ];
	ret.back.appearsIn = [ "NEWHOPE", "EMPIRE", "JEDI" ];
	ret.back.primaryFunction = "Astromech";

	return ret;
}

Starship[] getStarships() {
	Starship[] ret;

	ret ~= new Starship;
	ret.back.id = 3000;
	ret.back.name = "Millenium Falcon";
	ret.back.length = 34.37;

	ret ~= new Starship;
	ret.back.id = 3001;
	ret.back.name = "X-Wing";
	ret.back.length = 12.5;

	ret ~= new Starship;
	ret.back.id = 3002;
	ret.back.name = "TIE Advanced x1";
	ret.back.length = 9.2;

	ret ~= new Starship;
	ret.back.id = 3003;
	ret.back.name = "Imperial shuttle";
	ret.back.length = 20;

	return ret;
}

Review[][string] getReviews() {
	Review[][string] ret;
	ret["NEWHOPE"] = new Review[0];
	ret["EMPIRE"] = new Review[0];
	ret["JEDI"] = new Review[0];

	return ret;
}

struct Data {
	Human[] humans;
	Droid[] droids;
	Starship[] starships;
	Review[][string] reviews;

	static Data opCall() {
		Data ret;
		ret.humans = getHumans();
		ret.droids = getDroids();
		ret.starships = getStarships();
		ret.reviews = getReviews();
		return ret;
	}

	Character getHero(string episode) {
		if(episode == "EMPIRE") {
			// Luke is the hero of Episode V.
			foreach(h; this.humans) {
				if(h.id == 1000) {
					return h;
				}
			}
		}
		foreach(d; this.droids) {
			if(d.id == 2001) {
				return d;
			}
		}
		return null;
	}

	Character getCharacter(long id) {
		foreach(h; this.humans) {
			if(h.id == id) {
				return h;
			}
		}
		
		foreach(d; this.droids) {
			if(d.id == id) {
				return d;
			}
		}
		return null;
	}

	Character[] getFriends(Character character) {
		return character.friends.map!(id => this.getCharacter(id)).array;
	}

	Review[] getReview(string episode) {
		return this.reviews[episode];
	}

	Human getHuman(long id) {
		foreach(h; this.humans) {
			if(h.id == id) {
				return h;
			}
		}
		return null;
	}

	Droid getDroid(long id) {
		foreach(d; this.droids) {
			if(d.id == id) {
				return d;
			}
		}
		return null;
	}

	Starship getStarship(long id) {
		foreach(s; this.starships) {
			if(s.id == id) {
				return s;
			}
		}
		return null;
	}
}

unittest {
	Data d = Data();
}

__EOF__

/**
 * Helper function to get a character by ID.
 */
function getCharacter(id) {
	// Returning a promise just to illustrate GraphQL.js's support.
	return Promise.resolve(humanData[id] || droidData[id]);
}

/**
 * Allows us to query for a character's friends.
 */
function getFriends(character) {
	return character.friends.map(id => getCharacter(id));
}

/**
 * Allows us to fetch the undisputed hero of the Star Wars trilogy, R2-D2.
 */
function getHero(episode) {
}

/**
 * Allows us to fetch the ephemeral reviews for each episode
 */
function getReviews(episode) {
	return reviews[episode];
}

/**
 * Allows us to query for the human with the given id.
 */
function getHuman(id) {
	return humanData[id];
}

/**
 * Allows us to query for the droid with the given id.
 */
function getDroid(id) {
	return droidData[id];
}

function getStarship(id) {
	return starshipData[id];
}

function toCursor(str) {
	return Buffer("cursor" + str).toString('base64');
}

function fromCursor(str) {
	return Buffer.from(str, 'base64').toString().slice(6);
}

const resolvers = {
	Query: {
		hero: (root, { episode }) => getHero(episode),
		character: (root, { id }) => getCharacter(id),
		human: (root, { id }) => getHuman(id),
		droid: (root, { id }) => getDroid(id),
		starship: (root, { id }) => getStarship(id),
		reviews: (root, { episode }) => getReviews(episode),
		search: (root, { text }) => {
			const re = new RegExp(text, 'i');

			const allData = [
				...humans,
				...droids,
				...starships,
			];

			return allData.filter((obj) => re.test(obj.name));
		},
	},
	Mutation: {
		createReview: (root, { episode, review }) => {
			reviews[episode].push(review);
			review.episode = episode;
			pubsub.publish(ADDED_REVIEW_TOPIC, {reviewAdded: review});
			return review;
		},
	},
	Subscription: {
		reviewAdded: {
				subscribe: withFilter(
						() => pubsub.asyncIterator(ADDED_REVIEW_TOPIC),
						(payload, variables) => {
								return (payload !== undefined) && 
								((variables.episode === null) || (payload.reviewAdded.episode === variables.episode));
						}
				),
		},
	},
	Character: {
		__resolveType(data, context, info){
			if(humanData[data.id]){
				return info.schema.getType('Human');
			}
			if(droidData[data.id]){
				return info.schema.getType('Droid');
			}
			return null;
		},
	},
	Human: {
		height: ({ height }, { unit }) => {
			if (unit === 'FOOT') {
				return height * 3.28084;
			}

			return height;
		},
		friends: ({ friends }) => friends.map(getCharacter),
		friendsConnection: ({ friends }, { first, after }) => {
			first = first || friends.length;
			after = after ? parseInt(fromCursor(after), 10) : 0;
			const edges = friends.map((friend, i) => ({
				cursor: toCursor(i+1),
				node: getCharacter(friend)
			})).slice(after, first + after);
			const slicedFriends = edges.map(({ node }) => node);
			return {
				edges,
				friends: slicedFriends,
				pageInfo: {
					startCursor: edges.length > 0 ? edges[0].cursor : null,
					hasNextPage: first + after < friends.length,
					endCursor: edges.length > 0 ? edges[edges.length - 1].cursor : null
				},
				totalCount: friends.length
			};
		},
		starships: ({ starships }) => starships.map(getStarship),
		appearsIn: ({ appearsIn }) => appearsIn,
	},
	Droid: {
		friends: ({ friends }) => friends.map(getCharacter),
		friendsConnection: ({ friends }, { first, after }) => {
			first = first || friends.length;
			after = after ? parseInt(fromCursor(after), 10) : 0;
			const edges = friends.map((friend, i) => ({
				cursor: toCursor(i+1),
				node: getCharacter(friend)
			})).slice(after, first + after);
			const slicedFriends = edges.map(({ node }) => node);
			return {
				edges,
				friends: slicedFriends,
				pageInfo: {
					startCursor: edges.length > 0 ? edges[0].cursor : null,
					hasNextPage: first + after < friends.length,
					endCursor: edges.length > 0 ? edges[edges.length - 1].cursor : null
				},
				totalCount: friends.length
			};
		},
		appearsIn: ({ appearsIn }) => appearsIn,
	},
	FriendsConnection: {
		edges: ({ edges }) => edges,
		friends: ({ friends }) => friends,
		pageInfo: ({ pageInfo }) => pageInfo,
		totalCount: ({ totalCount }) => totalCount,
	},
	FriendsEdge: {
		node: ({ node }) => node,
		cursor: ({ cursor }) => cursor,
	},
	Starship: {
		length: ({ length }, { unit }) => {
			if (unit === 'FOOT') {
				return length * 3.28084;
			}

			return length;
		},
		coordinates: () => {
			return [[1, 2], [3, 4]];
		}
	},
	SearchResult: {
		__resolveType(data, context, info){
			if(humanData[data.id]){
				return info.schema.getType('Human');
			}
			if(droidData[data.id]){
				return info.schema.getType('Droid');
			}
			if(starshipData[data.id]){
				return info.schema.getType('Starship');
			}
			return null;
		},
	},
}

/**
 * Finally, we construct our schema (whose starting query type is the query
 * type we defined above) and export it.
 */
export const StarWarsSchema = makeExecutableSchema({
	typeDefs: [schemaString],
	resolvers
});
