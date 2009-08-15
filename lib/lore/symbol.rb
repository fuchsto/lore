require('lore/clause')

class Symbol

  def intern
    self
  end
  
  # Do not overload Symbol#==
  def eq(other)
    Lore::Clause.new(self.to_s)==(other)
  end
  alias is eq
  def >=(other)
    Lore::Clause.new(self.to_s)>=(other)
  end
  def <=(other)
    Lore::Clause.new(self.to_s)<=(other)
  end
  def >(other)
    Lore::Clause.new(self.to_s)>(other)
  end
  def <(other)
    Lore::Clause.new(self.to_s)<=(other)
  end
  def <=>(other)
    Lore::Clause.new(self.to_s)<=>(other)
  end
  def not(other)
    Lore::Clause.new(self.to_s)<=>(other)
  end
  def like(other)
    Lore::Clause.new(self.to_s).like(other)
  end
  def ilike(other)
    Lore::Clause.new(self.to_s).ilike(other)
  end
  def has_element(other)
    Lore::Clause.new(self.to_s).has_element(other)
  end
  def has_element_like(other)
    Lore::Clause.new(self.to_s).has_element_like(other)
  end
  def has_element_ilike(other)
    Lore::Clause.new(self.to_s).has_element_ilike(other)
  end
  def in(other)
    Lore::Clause.new(self.to_s).in(other)
  end
  def not_in(other)
    Lore::Clause.new(self.to_s).not_in(other)
  end
  def between(s,e)
    Lore::Clause.new(self.to_s).between(s,e)
  end

end

