import std;

struct Coord
{
    int x = -1;
    int y = -1;
    
    int distance(Coord target)
    {
        return cast(int)sqrt(cast(float)(this.x-target.x)^^2 + (this.y-target.y)^^2);
    }
    
    static Coord random(Coord min, Coord max)
    {
        return Coord(
            uniform(min.x, max.x, rndGen),
            uniform(min.y, max.y, rndGen)
        );
    }
}

enum TileType
{
    empty,
    radar,
    trap,
    safeHole,
    enemyHole
}

struct Tile
{
    TileType type;
    int oreAmount;
    bool targeted = false;
    
    this(TileType type, int oreAmount = 0)
    {
        this.type = type;
        this.oreAmount = oreAmount;
    }
}

enum EntityType
{
    player = 0,
    enemy = 1,
    radar = 2,
    trap = 3
}

enum Item
{
    none = -1,
    radar = 2,
    trap = 3,
    ore = 4
}

enum ItemRequest
{
    radar = "RADAR",
    trap = "TRAP"
}

struct Entity
{
    int id; // unique id of the entity
    EntityType type; // 0 for your robot, 1 for other robot, 2 for radar, 3 for trap
    Coord pos; // position of the entity
    Item item; // if this entity is a robot, the item it is carrying (-1 for NONE, 2 for RADAR, 3 for TRAP, 4 for ORE)
    bool moved = false; // Has already written to stdout
    Coord target = Coord(); // Current target tile
    
    this(int id, int type, int x, int y, int item)
    {
        this.id = id;
        this.type = cast(EntityType) type;
        this.pos = Coord(x, y);
        this.item = cast(Item) item;
    }
    
    void move()
    {
        move(this.target); // Can be null
    }
    
    void move(Coord c)
    {
        if (!moved)
        {
            writeln("MOVE ", c.x, " ", c.y);
            moved = true;
        }
    }
    
    bool canDig()
    {
        if (pos.distance(target) <= 1)
            return true;
        else
            return false;
    }
    
    void dig()
    {
        dig(this.target);
    }
    
    void dig(Coord pos)
    {
        if (!moved)
        {
            writeln("DIG ", pos.x, " ", pos.y);
            moved = true;
        }
    }
    
    void request(ItemRequest item)
    {
        if (!moved)
        {
            writeln("REQUEST ", item);
            moved = true;
        }
    }
    
    void wait()
    {
        if (!moved)
        {
            writeln("WAIT");
            moved = true;
        }
    }
}

struct Board
{
    Coord dimensions;

    int myScore;
    int opponentScore;
    
    Tile[Coord] tiles;
    
    int visibleEntities;
    int radarCooldown;
    int trapCooldown;
    
    Entity[int] entities;
    
    this(Coord dimensions)
    {
        this.dimensions = dimensions;
    }
    
    int countAvailableOres()
    {
        int totalOre = 0;
        foreach(tile; tiles)
        {
            if (tile.oreAmount > 0 && !tile.targeted)
                totalOre++;
        }
        return totalOre;
    }
    
    int countOres()
    {
        int totalOre = 0;
        foreach(tile; tiles)
        {
            totalOre += tile.oreAmount;
            //if (tile.targeted)
            //    totalOre = max(totalOre - 1, 0);
        }
        return totalOre;
    }
    
    int countRadars()
    {
        return tiles.byValue()
            .count!(a => a.type == TileType.radar)
            .to!int;
    }
}

class BoardParser
{
    static void readScore(ref Board board)
    {
        auto scores = readln.split.to!(int[]);
        board.myScore = scores[0].to!int;
        board.opponentScore = scores[1].to!int;
    }
    
    static void readGrid(ref Board board)
    {
        foreach (y; 0..board.dimensions.y) {
            auto input = readln.split;
            foreach (x; 0..board.dimensions.x) {
                Coord c = Coord(x, y);
                
                // Ores
                if (input[2*x] != "?")
                    if (input[2*x].to!int > 0)
                        board.tiles[c].oreAmount = input[2*x].to!int;
                       
                // Holes 
                if (input[2*x+1] == "1")
                    if(board.tiles[c].type == TileType.empty)
                        board.tiles[c].type = TileType.enemyHole;
            }
        }
    }
    
    static void readStats(ref Board board)
    {
        auto stats = readln.split.to!(int[]);
        board.visibleEntities = stats[0];
        board.radarCooldown = stats[1];
        board.trapCooldown = stats[2];
    }
    
    static void readEntities(ref Board board)
    {
        auto lastEntities = board.entities;
        board.entities = null;
        foreach (i; 0..board.visibleEntities) {
            auto entity = readln.split.to!(int[]);
            int id = entity[0];
            int type = entity[1];
            int x = entity[2];
            int y = entity[3];
            int item = entity[4];
            board.entities[id] = Entity(id, type, x, y, item);
            if (id in lastEntities)
                board.entities[id].target = lastEntities[id].target;
        }
    }
}

class Game
{
    Board board;
    Board lastBoard;
    
    Coord dimensions;
    
    int turn = 0;
    
    void readInit()
    {
        auto input = readln.split.to!(int[]);
        dimensions = Coord(input[0], input[1]);
    }
    
    void boardInit()
    {
        board = Board(dimensions);
        foreach (y; 0..board.dimensions.y)
            foreach (x; 0..board.dimensions.x)
            {
                Coord c = Coord(x, y);
                board.tiles[c] = Tile(TileType.empty);
            }
    }
        
    this()
    {
        readInit();
        boardInit();
    }
    
    public void startTurn()
    {
        lastBoard = board;
        
        BoardParser.readScore(board);
        BoardParser.readGrid(board);
        BoardParser.readStats(board);
        BoardParser.readEntities(board);
    }
    
    public void move()
    {
        auto playerRobots =
            board.entities
            .byPair
            .filter!(a => a.value.type == EntityType.player)
            .assocArray;

        foreach(id; playerRobots.keys.sort)
        {
            Entity* e = &board.entities[id];
            stderr.writeln(*e);
            
            if (e.pos == Coord(-1, -1)) // ded
            {
                e.wait();
                continue;
            }
            
            Tile* currTile = &board.tiles[e.pos];
            
            bool radarCondition =
                (board.countOres() < 12 && (e.id == 0 || e.id == 5));
                //|| (board.countOres() < 8 && (e.id == 4 || e.id == 9));
            
            if (e.item == Item.ore) // Always deliver ore
            {
                e.move(Coord(0, e.pos.y));
            }
            else if (radarCondition) // Radar
            {
                if (e.item != Item.radar) // Restock on radar
                {
                    // TODO: Check cooldown
                    e.request(ItemRequest.radar);
                }
                else if (e.target == Coord() || isDanger(e.target)) // Target is not set
                {
                    Coord target = nextRadar(e.pos);
                    board.tiles[target].targeted = true;
                    e.target = target;
                    e.move();
                }
                else if (e.canDig())
                {
                    if (e.item == Item.trap)
                        currTile.type = TileType.trap;
                    else if (e.item == Item.radar)
                        currTile.type = TileType.radar;
                    else
                        currTile.type = TileType.safeHole;
                    
                    e.dig();
                    currTile.targeted = false;
                    e.target = Coord();
                }                
                else
                {
                    e.move();
                }
            }
            else if (e.item != Item.ore)
            {
                if (board.countOres() == 0)
                {
                    e.target = nextRadar(e.pos);
                    e.dig();
                }
                else if (e.target == Coord() || isDanger(e.target) || board.tiles[e.target].oreAmount == 0)
                {
                    e.target = nextOre(e.pos);
                    board.tiles[e.target].targeted = true;
                    if (e.pos.x == 0 && board.trapCooldown == 0 && e.id != 0)
                        e.request(ItemRequest.trap);
                    else
                        e.move();
                }
                else if (e.pos != e.target)
                {
                    e.move();
                }
                else if (e.pos == e.target)
                {
                    if (e.item == Item.trap)
                        currTile.type = TileType.trap;
                    else if (e.item == Item.radar)
                        currTile.type = TileType.radar;
                    else
                        currTile.type = TileType.safeHole;
                        
                    e.dig();
                    board.tiles[e.target].oreAmount = max(board.tiles[e.target].oreAmount - 1, 0);
                    e.target = Coord();
                    currTile.targeted = false;
                }
            }
        }
    }
    
    public void endTurn()
    {
        turn++;
    }
    
    Coord nextRadar(Coord pos)
    {
        if (board.countRadars() > 0)
        {
            Coord c;
            Coord goodEnough;
            Tile[Coord] radars = board.tiles.byPair.filter!(a => a.value.type == TileType.radar).assocArray;
            foreach(x; 4..board.dimensions.x-3)
            {
                foreach(y; 3..board.dimensions.y-3)
                {
                    c = Coord(x, y);
                    bool ideal = true;
                    if (!isDanger(c) && !board.tiles[c].targeted)
                    {
                        foreach(radarPos, radar; radars)
                        {
                            auto dist = c.distance(radarPos);
                            if (dist < 6)
                            {
                                if(!isDanger(c))
                                {
                                    ideal = false;
                                    break;
                                }
                                else
                                    goodEnough = c;
                            }
                        }
                        if (ideal)
                            return c;
                    }
                }
            }
            return c;
        } else {
            return Coord.random(
                Coord(3, max(pos.y-1, 0)),
                Coord(5, min(pos.y+1, board.dimensions.y))
            );
        }
    }
    
    Coord nextOre(Coord pos)
    {
        if (board.countAvailableOres() > 0)
        {
            Coord destination = Coord();
            Coord goodEnough = Coord();
            int result = int.max;
            Tile[Coord] ores = board.tiles.byPair.filter!(a => a.value.oreAmount > 0).assocArray;
            foreach(orePos, ore; ores)
            {
                int dist = pos.distance(orePos);
                if (dist < result)
                {
                    if (!isDanger(orePos) && !board.tiles[orePos].targeted)
                    {
                        destination = orePos;
                        result = dist;
                    }
                    if (goodEnough == Coord())
                        goodEnough = orePos;
                }
            }
            if (destination == Coord())
            {
                stderr.writeln("No valid ore found");
                return goodEnough;
            }
            return destination;
        } else {
            return Coord.random(
                Coord(0, 0),
                Coord(board.dimensions.x/4, board.dimensions.y)
            );
        }
    }
    
    bool isDanger(Coord c)
    {
        if(isTrap(board.tiles[c]))
            return true;

        int nearbyTraps = 0;
        foreach(trapPos, trap; board.tiles.byPair.filter!(x => x.value.type == TileType.trap).assocArray)
                if (c.distance(trapPos) < 2)
                    nearbyTraps++;

        if (nearbyTraps > 0)                    
            foreach(e; board.entities.byValue.filter!(x => x.type == EntityType.enemy))
                if (c.distance(e.pos) < 2)
                    return true;

        return false;
    }
    
    bool isTrap(Tile t)
    {
        if (t.type == TileType.trap || t.type == TileType.enemyHole)
            return true;
        else
            return false;
    }
}

void main()
{
    Game game = new Game();
    
    while (1) {
        game.startTurn();
        game.move();
        game.endTurn();
    }
}
