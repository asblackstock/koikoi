######### TODO
# card comparator for sort
# lucky hands
# sake cup in plains?
# hanami -> curtain?

require 'csv'

ID_HANAMI    = 12
ID_BUTTERFLY = 24
ID_BOAR      = 28
ID_MOON      = 32
ID_SAKE      = 36
ID_DEER      = 40
ID_RAIN_MAN  = 44

class Card
  attr_reader :id
  attr_reader :suit
  attr_reader :special
  attr_reader :name

  def initialize(row)
    @id = row[0].to_i
    @suit = row[1]
    @special = row[2] || ""
    @name = row[3]
  end

  def to_s
    name = if ["BR", "AN"].include?(@special)
      @name
    elsif ["B", "BS", "BB"].include?(@special)
      @name.split(" ").first + " " + @special
    else
      @name
    end
    "(#{@id.to_s.rjust(2, '0')}) #{name}".ljust(17)
  end
end

class Deck
  attr_reader :state

  def initialize
    @dict = {}
    @state = []
    CSV.foreach("./deck.csv") do |row|
      card = Card.new(row)
      @dict[card.id] = card
      @state << card
    end
  end

  def shuffle
    @state = @state.shuffle
  end

  def deal
    p2 = []
    pot = []
    p1 = []
    4.times.each {
      p2 << @state.shift
      p2 << @state.shift
      pot << @state.shift
      pot << @state.shift
      p1 << @state.shift
      p1 << @state.shift
    }
    return [p1, p2, pot]
  end

  def draw
    return @state.shift
  end

  def count
    return @state.count
  end

  def info(id)
    return @dict[id]
  end

  def rand(n)
    return @state.shuffle.first(n)
  end
end

class Player
  attr_reader :name
  attr_accessor :hand
  attr_reader :board
  attr_reader :koikoi_count

  def initialize(name)
    @name = name
    @hand = []
    @board = []
    @koikoi_count = 0
  end
end

class Yaku
  attr_reader :id
  attr_reader :name
  attr_reader :cards
  attr_reader :points
  attr_accessor :exclusive_to

  def initialize(name, cards, points)
    @id = rand(1000000000..9999999999)
    @name = name
    @cards = cards
    @points = points
    @exclusive_to = []
  end
end

class Game
  attr_reader :deck
  attr_reader :player1
  attr_reader :player2
  attr_reader :pot
  attr_reader :to_play
  attr_reader :phase

  PHASE_SEQUENCE = ["PP1", "D", "PP2", "KD"]

  def initialize
    @deck = Deck.new
    @deck.shuffle
    @player1 = Player.new("Agu")
    @player2 = Player.new("Yo")
    self.determine_first

    @deck.shuffle
    p1, p2, pot = @deck.deal
    @player1.hand = p1
    @player2.hand = p2
    @pot = pot
    @phase = 0

    self.show_state
  end

  def determine_first
    determined = false
    ix = 0
    while !determined
      p1c, p2c = @deck.state[ix,2]
      if p1c.suit == p2c.suit
        puts "#{@player1.name} draws #{p1c.name}, #{@player2.name} draws #{p2c.name}"
        ix += 2
      else
        @to_play = (p1c.id < p2c.id) ? @player1 : @player2
        determined = true
        puts "#{@player1.name} draws #{p1c.name}, #{@player2.name} draws #{p2c.name}, #{@to_play.name} to play"
      end
    end
  end

  def show_state(view=nil)
    lines = ["Deck (#{@deck.count})"]
    lines << ""
    lines << @player1.name
    lines << ("HND: " + @player1.hand.map(&:to_s).join(""))
    lines << ("BRD: " + @player1.board.sort { |a, b| a.special <=> b.special }.map(&:to_s).join(""))
    lines << ""
    lines << "Pot"
    lines << ("     " + @pot.map(&:to_s).join(""))
    lines << ""
    lines << @player2.name
    lines << ("HND: " + @player2.hand.map(&:to_s).join(""))
    lines << ("BRD: " + @player2.board.sort { |a, b| a.special <=> b.special }.map(&:to_s).join(""))
    puts lines.join("\n")
  end

  # Game loop / player lifecycle

  def capture(give_id, take_id)
    begin
      raise "Cannot pick up cards now." if !["PP1", "PP2"].include?(PHASE_SEQUENCE[@phase])
      raise "Cannot play that card." if !@to_play.hand.map(&:id).include?(give_id)
      raise "That card is not in the pot." if !@pot.map(&:id).include?(take_id)
      raise "Cards do not match." if @deck.info(give_id).suit != @deck.info(take_id).suit

      @to_play.board << @pot.slice!(@pot.index(@deck.info(take_id)))
      @to_play.board << @to_play.hand.slice!(@to_play.hand.index(@deck.info(give_id)))
      puts "#{@to_play.name} takes #{@to_play.board[-2].name} with #{@to_play.board[-1].name}."

      @phase += 1
      self.show_state



# detect koikoi



    rescue => e
      puts e.message
    end
  end

  def draw
    begin
      raise "Cannot draw cards now." if "D" != PHASE_SEQUENCE[@phase]
      top_card = @deck.draw
      raise "The deck is empty." if top_card == nil
      @to_play.hand << top_card

      @phase += 1
      self.show_state
    rescue => e
      puts e.message
    end
  end

  def pass
# guard

    @phase += 1

  # detect koikoi
  end

  def find_yaku(hand)
    yakus = []

    # Plains
    cards = hand.select{ |c| c.special == "" }
    if cards.count >= 10
      yakus << Yaku.new(
        "Plain #{cards.count}",
        cards,
        1 + (cards.count - 10)
      )
    end

    # Animals
    cards = hand.select{ |c| c.special == "AN" }
    if cards.count >= 5
      yakus << Yaku.new(
        "Animals #{cards.count}",
        cards,
        1 + (cards.count - 5)
      )
    end

    # Ribbons
    ribbon_cards = hand.select{ |c| c.special == "B" || c.special == "BS" || c.special == "BB"}
    total_ribbons = ribbon_cards.count
    if total_ribbons >= 5
      yakus << Yaku.new(
        "Ribbons #{total_ribbons}",
        ribbon_cards,
        1 + (total_ribbons - 5)
      )
    end

    # Poetry ribbons
    cards = hand.select{ |c| c.special == "BS" }
    if cards.count == 3
      yakus << Yaku.new(
        "Poetry Ribbons #{total_ribbons}",
        ribbon_cards,
        5 + (total_ribbons - 3)
      )
    end

    # Blue ribbons
    cards = hand.select{ |c| c.special == "BB" }
    if cards.count == 3
      yakus << Yaku.new(
        "Blue Ribbons #{total_ribbons}",
        ribbon_cards,
        5 + (total_ribbons - 3)
      )
    end

    # Moon viewing
    hand_ids = hand.map(&:id)
    if hand_ids.include?(ID_MOON) && hand_ids.include?(ID_SAKE)
      yakus << Yaku.new(
        "Moon Viewing",
        [@deck.info(ID_MOON), @deck.info(ID_SAKE)],
        5
      )
    end

    # Cherry blossom viewing
    if hand_ids.include?(ID_HANAMI) && hand_ids.include?(ID_SAKE)
      yakus << Yaku.new(
        "Cherry Blossom Viewing",
        [@deck.info(ID_HANAMI), @deck.info(ID_SAKE)],
        5
      )
    end

    # Boar-deer-butterfly
    if hand_ids.include?(ID_BOAR) && hand_ids.include?(ID_DEER) && hand_ids.include?(ID_BUTTERFLY)
      animals = hand.select{ |c| c.special == "AN" }
      yakus << Yaku.new(
        "Boar-Deer-Butterfly #{animals.count}",
        animals,
        5 + (animals.count - 3)
      )
    end

    # Brights
    cards = hand.select{ |c| c.special == "BR" }

    # Three brights
    if cards.count == 3 && !cards.map(&:id).include?(ID_RAIN_MAN)
      yakus << Yaku.new(
        "Three Brights",
        cards,
        5
      )
    end

    # Rainy four brights
    if cards.count == 4 && cards.map(&:id).include?(ID_RAIN_MAN)
      yakus << Yaku.new(
        "Rainy Four Brights",
        cards,
        7
      )
    end

    # Four brights
    if cards.count == 4 && !cards.map(&:id).include?(ID_RAIN_MAN)
      yakus << Yaku.new(
        "Four Brights",
        cards,
        8
      )
    end

    # Five brights
    if cards.count == 5
      yakus << Yaku.new(
        "Five Brights",
        cards,
        10
      )
    end


    # TODO: Determine exclusivity


    return yakus
  end
end




######### New Game
# g = Game.new

