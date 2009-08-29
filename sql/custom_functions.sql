
-- These functions are needed for convenience operations Lore offers, so far
-- LIKE-operator and ILIKE-operators on array elements. 
-- If you intend to use custom SQL functions that have to be defined in 
-- your database, this is where they should be placed. 

-- Provide LIKE-operator for arrays: (Model.an_array_attribute.has_element_like('%'+foo)
create function rlike(text,text) returns bool as 'select $2 like $1' language sql strict immutable; 
create operator ~~~ (procedure = rlike, leftarg = text, rightarg = text, commutator = ~~);
-- Provide LIKE-operator for arrays: (Model.an_array_attribute.has_element_ilike('%'+foo)
create function irlike(text,text) returns bool as 'select $2 ilike $1' language sql strict immutable; 
create operator ~~~~ (procedure = irlike, leftarg = text, rightarg = text, commutator = ~~);


