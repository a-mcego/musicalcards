#include <iostream>
#include <vector>
#include <algorithm>
#include <map>
#include <ctime>
#include <random>
using std::cout, std::endl, std::cin;
using uint = unsigned int;

struct Card
{
    int suit{}; // from 0 to 4 (Violin, Flute, tRumpet, Timpani, Piano)
    int note{}; // from 0 to 6 (C, D, E, F, G, A, B)
    int accidental{}; // 0 (flat), 1 (natural), 2 (sharp)
    int noteID() const
    {
        return note*3+accidental;
    }

    auto ToString()
    {
        std::string str(5,'-');
        str[0] = "VFTTP"[suit];
        str[1] = "ilrii"[suit];
        str[3] = "CDEFGAB"[note];
        str[4] = "b #"[accidental];
        return str;
    }
};

enum HandType
{
    Scale,
    Solo,
    Tutti,
    SoloScale,
    TuttiScale,
    All,
    ThreeOfAKind,
    FourOfAKind,
    FiveOfAKind,
    TwoPairs,
    OnePair,
    SameRootNote,
    SameAccidental,
    TotalTypes
};

const char* HandNames[] =
{
    "Scale",
    "Solo",
    "Tutti",
    "SoloScale",
    "TuttiScale",
    "All",
    "Three of a Kind",
    "Four of a Kind",
    "Five of a Kind",
    "Two Pairs",
    "One Pair",
    "Same Root Note",
    "Same Accidental",
    "TotalTypes"
};

bool compareByNote(const Card& a, const Card& b)
{
    return a.note < b.note;
}
bool isThreeOfAKind(const std::vector<Card>& hand, const auto& counts)
{
	for (const auto& count : counts)
	{
		if (count.second == 3)
			return true;
	}
	return false;
}

bool isFourOfAKind(const std::vector<Card>& hand, const auto& counts)
{
	for (const auto& count : counts)
	{
		if (count.second == 4)
			return true;
	}
	return false;
}

bool isFiveOfAKind(const std::vector<Card>& hand, const auto& counts)
{
	for (const auto& count : counts)
	{
		if (count.second == 5)
			return true;
	}
	return false;
}

bool isTwoPairs(const std::vector<Card>& hand, const auto& counts)
{
    int pairCount = 0;
    for (const auto& count : counts)
    {
        if (count.second == 2)
            pairCount++;
    }
    return pairCount == 2;
}

bool isOnePair(const std::vector<Card>& hand, const auto& counts)
{
    for (const auto& count : counts)
    {
        if (count.second == 2)
            return true;
    }
    return false;
}

bool isSolo(const std::vector<Card>& hand)
{
    for (const auto& card : hand)
    {
        if (card.suit != hand[0].suit)
            return false;
    }
    return true;
}

bool isSameRootNote(const std::vector<Card>& hand)
{
    for (const auto& card : hand)
    {
        if (card.note != hand[0].note)
            return false;
    }
    return true;
}

bool isSameAccidental(const std::vector<Card>& hand)
{
    for (const auto& card : hand)
    {
        if (card.accidental != hand[0].accidental)
            return false;
    }
    return true;
}

bool isTutti(const std::vector<Card>& hand)
{
    uint suit=0U;
    for (const auto& card : hand)
    {
        suit |= (1U << card.suit);
    }
    return suit == 0b11111;
}

const uint flats[8] =
{
    0b01'01'01'01'01'01'01,
    0b00'01'01'01'01'01'01,
    0b00'01'01'01'00'01'01,
    0b00'00'01'01'00'01'01,
    0b00'00'01'01'00'00'01,
    0b00'00'00'01'00'00'01,
    0b00'00'00'01'00'00'00,
    0b00'00'00'00'00'00'00,
};
const uint sharps[8] =
{
    0b01'01'01'01'01'01'01,
    0b01'01'01'10'01'01'01,
    0b01'01'01'10'01'01'10,
    0b01'01'10'10'01'01'10,
    0b01'01'10'10'01'10'10,
    0b01'10'10'10'01'10'10,
    0b01'10'10'10'10'10'10,
    0b10'10'10'10'10'10'10,
};

bool isScale(const std::vector<Card>& hand)
{
    //first check the notes themselves
    uint noteTypes = 0, accidentals = 0;
    for (int i = 0; i < hand.size(); ++i)
    {
        noteTypes |= (1 << hand[i].note);
        accidentals |= (uint(hand[i].accidental) << uint(hand[i].note*2));
    }

    bool retValue = false;

    if (noteTypes == 0b0011111) // C to G
    {
        uint mask = 0b00'00'11'11'11'11'11;
        if (accidentals == (flats[7]&mask))
            retValue=true; //Cb major!
        else if (accidentals == (flats[3]&mask))
            retValue=true; //C minor!
        else if (accidentals == (flats[0]&mask))
            retValue=true; //C major!
        else if (accidentals == (sharps[3]&mask))
            retValue=true; //C# minor!
        else if (accidentals == (sharps[7]&mask))
            retValue=true; //C# major!
    }
    else if (noteTypes == 0b0111110) // D to A
    {
        uint mask = 0b00'11'11'11'11'11'00;
        if (accidentals == (flats[5]&mask))
            retValue=true; //Db major!
        else if (accidentals == (flats[1]&mask))
            retValue=true; //D minor!
        else if (accidentals == (sharps[2]&mask))
            retValue=true; //D major!
        else if (accidentals == (sharps[6]&mask))
            retValue=true; //D# minor!
    }
    else if (noteTypes == 0b1111100) // E to B
    {
        uint mask = 0b11'11'11'11'11'00'00;
        if (accidentals == (flats[6]&mask))
            retValue=true; //Eb minor!
        else if (accidentals == (flats[3]&mask))
            retValue=true; //Eb major!
        else if (accidentals == (sharps[1]&mask))
            retValue=true; //E minor!
        else if (accidentals == (sharps[4]&mask))
            retValue=true; //E major!
    }
    else if (noteTypes == 0b1111001) // F to C
    {
        uint mask = 0b11'11'11'11'00'00'11;
        if (accidentals == (flats[4]&mask))
            retValue=true; //F minor!
        else if (accidentals == (flats[1]&mask))
            retValue=true; //F major!
        else if (accidentals == (sharps[3]&mask))
            retValue=true; //F# minor!
        else if (accidentals == (sharps[6]&mask))
            retValue=true; //F# major!
    }
    else if (noteTypes == 0b1110011) // G to D
    {
        uint mask = 0b11'11'11'00'00'11'11;
        if (accidentals == (flats[6]&mask))
            retValue=true; //Gb major!
        else if (accidentals == (flats[2]&mask))
            retValue=true; //G minor!
        else if (accidentals == (sharps[1]&mask))
            retValue=true; //G major!
        else if (accidentals == (sharps[5]&mask))
            retValue=true; //G# minor!
    }
    else if (noteTypes == 0b1100111) // A to E
    {
        uint mask = 0b11'11'00'00'11'11'11;
        if (accidentals == (flats[7]&mask))
            retValue=true; //Ab minor!
        else if (accidentals == (flats[4]&mask))
            retValue=true; //Ab major!
        else if (accidentals == (flats[0]&mask))
            retValue=true; //A minor!
        else if (accidentals == (sharps[3]&mask))
            retValue=true; //A major!
        else if (accidentals == (sharps[7]&mask))
            retValue=true; //A# minor!
    }
    else if (noteTypes == 0b1001111) // B to F
    {
        uint mask = 0b11'00'00'11'11'11'11;
        if (accidentals == (flats[5]&mask))
            retValue=true; //Bb minor!
        else if (accidentals == (flats[2]&mask))
            retValue=true; //Bb major!
        else if (accidentals == (sharps[2]&mask))
            retValue=true; //B minor!
        else if (accidentals == (sharps[5]&mask))
            retValue=true; //B major!
    }
    return retValue;
}

void AnalyzeWin(std::vector<Card>& hand, std::vector<int>& handCounts)
{
    if (isScale(hand))
    {
        handCounts[Scale]++;
        if (isSolo(hand))
        {
            handCounts[SoloScale]++;
        }
        if (isTutti(hand))
        {
            handCounts[TuttiScale]++;
        }
    }
    if (isSolo(hand))
    {
        handCounts[Solo]++;
    }
    if (isSameRootNote(hand))
    {
        handCounts[SameRootNote]++;
    }
    if (isSameAccidental(hand))
    {
        handCounts[SameAccidental]++;
    }
    if (isTutti(hand))
    {
        handCounts[Tutti]++;
    }

    std::map<int, int> counts;
    for (const auto& card : hand)
    {
        counts[card.noteID()]++;
    }

    if (isThreeOfAKind(hand, counts))
    {
        handCounts[ThreeOfAKind]++;
    }
    if (isFourOfAKind(hand, counts))
    {
        handCounts[FourOfAKind]++;
    }
    if (isFiveOfAKind(hand, counts))
    {
        handCounts[FiveOfAKind]++;
    }
    if (isTwoPairs(hand, counts))
    {
        handCounts[TwoPairs]++;
    }
    if (isOnePair(hand, counts))
    {
        handCounts[OnePair]++;
    }
    handCounts[All]++;
}

int analyze()
{
    std::vector<Card> deck;
    std::vector<Card> hand(5);
    std::vector<int> handCounts(TotalTypes, 0);

    // Create a deck of musical cards
    for (int suit = 0; suit < 5; ++suit)
    {
        for (int note = 0; note < 7; ++note)
        {
            for (int accidental = 0; accidental < 3; ++accidental)
            {
                deck.push_back({suit, note, accidental});
            }
        }
    }

    // Generate all combinations of 5 cards
    std::vector<bool> v(deck.size());
    std::fill(v.end() - 5, v.end(), true);

    unsigned long int done = 0;
    auto starttime = clock();
    cout << starttime << endl;

    do
    {
        int handIndex = 0;
        for (int i = 0; i < deck.size(); ++i)
        {
            if (v[i])
            {
                hand[handIndex++] = deck[i];
            }
        }

        // Analyze the current hand
        AnalyzeWin(hand, handCounts);
        ++done;
        if (done%16384 == 0 && clock()-starttime >= 1000)
        {
            starttime += 1000;
            cout << done << endl;
        }
    } while (std::next_permutation(v.begin(), v.end()));

    for (int i = 0; i < TotalTypes; ++i)
    {
        std::cout << HandNames[i] << ": " << handCounts[i] << std::endl;
    }

    return 0;
}

int main() {
    std::vector<Card> deck;
    std::vector<Card> hand(5);

    // Create a deck of musical cards
    for (int suit = 0; suit < 5; ++suit) {
        for (int note = 0; note < 7; ++note) {
            for (int accidental = 0; accidental < 3; ++accidental) {
                deck.push_back({suit, note, accidental});
            }
        }
    }

    std::random_device rd;
    std::mt19937 g(rd());

    while(true)
    {
        std::shuffle(deck.begin(), deck.end(), g);
        cout << "Choose five:" << endl;
        cout << "[ 1 ] [ 2 ] [ 3 ] [ 4 ] [ 5 ] [ 6 ] [ 7 ] [ 8 ] [ 9 ]" << endl;
        for (int j = 0; j < 9; ++j)
        {
            cout << deck[j].ToString() << " ";
        }
        cout << endl;

        for(int choose=0; choose<5; ++choose)
        {
            int chosen_id=0;
            cin >> chosen_id;
            hand[choose] = deck[chosen_id-1];
        }
        cout << endl;

        std::vector<int> handCounts(TotalTypes, 0);
        AnalyzeWin(hand, handCounts);

        for (int i = 0; i < TotalTypes; ++i)
        {
            if (handCounts[i] > 0)
            {
                std::cout << HandNames[i] << ": " << handCounts[i] << std::endl;
            }
        }
        cout << endl;
    }
    return 0;
}
