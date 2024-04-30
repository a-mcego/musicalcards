#include <iostream>
#include <vector>
#include <algorithm>
#include <map>

struct Card {
    int suit{}; // from 0 to 3
    int number{}; // from 0 to 12
};

enum HandType {
    RoyalFlush,
    StraightFlush,
    FourOfAKind,
    FullHouse,
    Flush,
    Straight,
    ThreeOfAKind,
    TwoPair,
    OnePair,
    HighCard,
    TotalTypes
};

const char* HandNames[] =
{
    "RoyalFlush   ",
    "StraightFlush",
    "FourOfAKind  ",
    "FullHouse    ",
    "Flush        ",
    "Straight     ",
    "ThreeOfAKind ",
    "TwoPair      ",
    "OnePair      ",
    "HighCard     ",
    "TotalTypes   "
};

bool compareByNumber(const Card& a, const Card& b) {
    return a.number < b.number;
}

bool isFlush(const std::vector<Card>& hand) {
    int firstSuit = hand[0].suit;
    for (const auto& card : hand) {
        if (card.suit != firstSuit) return false;
    }
    return true;
}

bool isStraight(const std::vector<Card>& hand) {
    if (hand[0].number == 0 && hand[1].number == 9 && hand[2].number == 10 && hand[3].number == 11 && hand[4].number == 12) {
        return true;
    }
    for (int i = 0; i < hand.size() - 1; ++i) {
        if (hand[i].number + 1 != hand[i + 1].number) {
            return false;
        }
    }
    return true;
}

bool isStraightFlush(const std::vector<Card>& hand) {
    return isStraight(hand) && isFlush(hand);
}

bool isRoyalFlush(const std::vector<Card>& hand) {
    return isStraightFlush(hand) && hand.front().number == 0 && hand.back().number == 12;
}

void AnalyzeWin(std::vector<Card>& hand, std::vector<int>& handCounts) {
    if (hand.size() != 5) {
        std::cout << "Invalid hand size." << std::endl;
        return;
    }

    std::sort(hand.begin(), hand.end(), compareByNumber);

    if (isRoyalFlush(hand)) {
        handCounts[RoyalFlush]++;
        return;
    }
    if (isStraightFlush(hand)) {
        handCounts[StraightFlush]++;
        return;
    }

    std::map<int, int> frequency;
    for (const auto& card : hand) {
        frequency[card.number]++;
    }

    int pairs = 0;
    int threes = 0;
    int fours = 0;

    for (const auto& freq : frequency) {
        if (freq.second == 2) pairs++;
        if (freq.second == 3) threes++;
        if (freq.second == 4) fours++;
    }

    if (fours) {
        handCounts[FourOfAKind]++;
        return;
    }
    if (threes && pairs) {
        handCounts[FullHouse]++;
        return;
    }
    if (isFlush(hand)) {
        handCounts[Flush]++;
        return;
    }
    if (isStraight(hand)) {
        handCounts[Straight]++;
        return;
    }
    if (threes) {
        handCounts[ThreeOfAKind]++;
        return;
    }
    if (pairs == 2) {
        handCounts[TwoPair]++;
        return;
    }
    if (pairs == 1) {
        handCounts[OnePair]++;
        return;
    }

    handCounts[HighCard]++;
}

int main() {
    std::vector<Card> deck;
    std::vector<Card> hand(5);
    std::vector<int> handCounts(TotalTypes, 0);

    // Create a standard deck of cards
    for (int suit = 0; suit < 4; ++suit) {
        for (int number = 0; number < 13; ++number) {
            deck.push_back({suit, number});
        }
    }

    // Generate all combinations of 5 cards
    std::vector<bool> v(deck.size());
    std::fill(v.end() - 5, v.end(), true);

    do {
        int handIndex = 0;
        for (int i = 0; i < deck.size(); ++i) {
            if (v[i]) {
                hand[handIndex++] = deck[i];
            }
        }

        // Analyze the current hand
        AnalyzeWin(hand, handCounts);

    } while (std::next_permutation(v.begin(), v.end()));

    // Optionally, print the results
    for (int i = 0; i < TotalTypes; ++i) {
        std::cout << HandNames[i] << ": " << handCounts[i] << std::endl;
    }

    return 0;
}
