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
    none = -1,
    radar = 2,
    trap = 3,
    ore = 4
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
        foreach(i, e; entities.filter!(e => e.type == EntityType.player).array)
        {
            stderr.writeln(e);

            if (e.item == Item.ore)
            {
                writeln("MOVE ", 0, " ", e.pos.y);
            }
            else if (e.id == 2 && e.item != Item.radar)
            {
                writeln("REQUEST RADAR");
            }
            else if (e.item != Item.ore)
            {
                foreach(ore; ores)
                {
                    if (false && ore.pos == e.pos)
                    {
                        writeln("DIG ", e.pos.x, " ", e.pos.y);
                        break;
                    }
                }
                if (uniform(0, 5, rndGen) == 0)
                    writeln("DIG ", e.pos.x, " ", e.pos.y);
                else
                    writeln("MOVE ", e.pos.x + 2, " ", e.pos.y);
            }
        }
    }
}

void main()
{
    Game game = new Game();

    while (1) {
        game.startTurn();
        game.move();
    }
}
