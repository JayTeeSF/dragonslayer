class Character
  attr_reader :strength, :hit_power, :total_damage, :name
  STRENGTH = 4
  HIT_POWER = 1..5
  def initialize(options={})
    @strength = options[:strength] || STRENGTH
    @hit_power = options[:hit_power] || HIT_POWER
    @total_damage = options[:total_damage] || 0
    @name = options[:name] || self.class.to_s

    # TODO add some kind of weighting to the possible_damage array
    @miss_array = options[:miss_array] || [0]
  end

  def possible_damage
    hit_power.to_a + @miss_array
  end

  def dead?
    total_damage > strength
  end

  def hit(damage)
    @total_damage = @total_damage + damage
  end

  def to_s
    name
  end
end
