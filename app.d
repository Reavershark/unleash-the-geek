import std;

struct Coord
{
    int x, y;
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
    NONE = -1,
    RADAR = 2,
    TRAP = 3,
    ORE = 4
}

struct Entity
{
    int id; // unique id of the entity
    EntityType type; // 0 for your robot, 1 for other robot, 2 for radar, 3 for trap
    Coord pos; // position of the entity
    Item item; // if this entity is a robot, the item it is carrying (-1 for NONE, 2 for RADAR, 3 for TRAP, 4 for ORE)
    
    this(int id, int type, int x, int y, int item)
    {
        this.id = id;
        this.type = cast(EntityType) type;
        this.pos = Coord(x, y);
        this.item = cast(Item) item;
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
    
    void readInit()
    {
        auto dimentions = readln.split;
        width = dimentions[0].to!int;
        height = dimentions[1].to!int;
    }
    
    void readScore()
    {
        auto scores = readln.split;
        myScore = scores[0].to!int;
        opponentScore = scores[1].to!int;
    }
    
    void readGrid()
    {
        ores = null;
        holes = null;
        for (int y = 0; y < height; y++) {
            auto input = readln.split;
            for (int x = 0; x < width; x++) {
                if (input[2*x] != "?")
                    ores ~= Ore(x, y, input[0].to!int);
                if (input[2*x+1] == "1")
                    holes ~= Coord(x, y);
            }
        }
    }
    
    void readStats()
    {
        auto stats = readln.split;
        visibleEntities = stats[0].to!int;
        radarCooldown = stats[1].to!int;
        trapCooldown = stats[2].to!int;
    }
    
    void readEntities()
    {
        entities = null;
        for (int i = 0; i < visibleEntities; i++) {
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
    }
}

void main()
{
    Game game = new Game();
    
    while (1) {
        game.startTurn();
        for (int i = 0; i < 5; i++) {
            writeln("WAIT"); // WAIT|MOVE x y|DIG x y|REQUEST item
        }
    }
}
