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

struct Ore
{
    Coord pos;
    int amount = 0;
    
    this(int x, int y, int amount)
    {
        this.pos = Coord(x, y);
        this.amount = amount;
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
    
    void move(Coord pos)
    {
        if (!moved)
        {
            writeln("MOVE ", pos.x, " ", pos.y);
            moved = true;
        }
    }
    
    void dig()
    {
        dig(this.pos);
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
        if (!moved )
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

class Game
{
    int width;
    int height;
    
    int myScore;
    int opponentScore;
    
    Ore[] ores;
    Coord[] holes;
    
    int visibleEntities;
    int radarCooldown;
    int trapCooldown;
    
    Entity[] entities;
    Entity[] lastEntities;
    
    int turn = 0;
    
    Coord[] radars;
    
    void readInit()
    {
        auto dimentions = readln.split.to!(int[]);
        width = dimentions[0];
        height = dimentions[1];
    }
    
    void readScore()
    {
        auto scores = readln.split.to!(int[]);
        myScore = scores[0].to!int;
        opponentScore = scores[1].to!int;
    }
    
    void readGrid()
    {
        ores = null;
        holes = null;
        foreach (y; 0..height) {
            auto input = readln.split;
            foreach (x; 0..width) {
                if (input[2*x] != "?")
                    if (input[2*x].to!int > 0)
                        ores ~= Ore(x, y, input[2*x].to!int);
                if (input[2*x+1] == "1")
                    holes ~= Coord(x, y);
            }
        }
    }
    
    void readStats()
    {
        auto stats = readln.split.to!(int[]);
        visibleEntities = stats[0];
        radarCooldown = stats[1];
        trapCooldown = stats[2];
    }
    
    void readEntities()
    {
        lastEntities = entities.dup;
        entities = null;
        foreach (i; 0..visibleEntities) {
            auto entity = readln.split.to!(int[]);
            int id = entity[0];
            int type = entity[1];
            int x = entity[2];
            int y = entity[3];
            int item = entity[4];
            entities ~= Entity(id, type, x, y, item);
        }
    }
    
    this()
    {
        readInit();
    }
    
    public void startTurn()
    {
        readScore();
        readGrid();
        readStats();
        readEntities();
        stderr.writeln(ores);
        stderr.writeln(holes);
    }
    
    public void move()
    {
        foreach(ref e; entities.filter!(e => e.type == EntityType.player))
        {
            stderr.writeln(e);
            
            if (turn > 0)
            {
                Entity lastEntity = lastEntities.filter!(x => x.id == e.id).array[0];
                e.target = lastEntity.target;
            }
            
            
            if (e.item == Item.ore) // Always deliver ore
            {
                e.move(Coord(0, e.pos.y));
            }
            if (radars.length < 8 && (e.id == 0 || e.id == 5)) // Robot 0 places radars
            {
                if (e.item != Item.radar) // Restock on radar
                {
                    // TODO: Check cooldown
                    e.request(ItemRequest.radar);
                }
                else if (e.target == Coord()) // Target is not set
                {
                    e.target = nextRadar(e.pos);
                    e.move();
                }
                else if (e.target != e.pos)
                {
                    e.move();
                }
                else
                {
                    Coord radar = e.target;
                    e.dig();
                    radars ~= e.pos;
                    e.target = Coord();
                }
            }
            else if (e.item != Item.ore)
            {
                if (e.target == Coord() || !ores.any!(x => x.pos == e.target))
                {
                    e.target = nextOre(e.pos).pos;
                    e.move();
                }
                else if (e.pos != e.target)
                {
                    
                    e.move();
                }
                else if (e.pos == e.target)
                {
                    e.dig();
                    e.target = Coord();
                }
            }
        }
    }
    
    public void endTurn()
    {
        turn++;
    }
    
    Coord nextRadar(Coord pos) // Argument not yet used
    {

        if (radars.length > 0)
        {
            Coord c;
            foreach(y; 3..height-3)
            {
                foreach(x; 3..width-3)
                {
                    c = Coord(x, y);
                    bool ideal = true;
                    foreach(radar; radars)
                    {
                        auto dist = c.distance(radar);
                        if ( dist < 6 )
                        {
                            ideal = false;
                            break;
                        }
                    }
                    if (ideal)
                            return c;
                }
            }
            stderr.writeln("Random radar location");
            return c;
        } else {
            return Coord(width/4, height/2);
        }
    }
    
    Ore nextOre(Coord pos)
    {
        if (ores.length > 0)
        {
            Ore destination;
            int result = int.max;
            foreach(ore; ores)
            {
                int dist = pos.distance(ore.pos);
                if ( dist < result && ore.amount > 0)
                {
                    destination = ore;
                    result = dist;
                }
            }
            stderr.writeln(destination);
            return destination;
        } else {
            return Ore(width/3, height/2, 0);
        }
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
