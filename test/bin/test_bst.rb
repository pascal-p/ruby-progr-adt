#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# conditional requires
begin
  require 'rubygems'
  require 'bundler/setup'

rescue Exception => e
  STDERR.puts("[!] ignoring #{e.message} - this is is fine if you are not using bundler") if $DEBUG
end

# un-conditional requires
require 'minitest/autorun'

$LOAD_PATH.push File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib"))
# $LOAD_PATH.push File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require 'bst'

class TestBST < MiniTest::Unit::TestCase

  def setup
    @tree_empty = BST::Tree.new
    @ary = [ 8, 3, 10, 1, 6, 4, 7, 14, 12] # do not change this array
    # => otherwise this will break some expectations
    @tree = BST::Tree.new
    @ary.each { |v| @tree.insert(v) }
    #
    # @lbd = ->(x) { x } # the Id fun is the default for the traversal impl.
  end

  def teardown
    @tree = nil
    @ary = nil
  end

  def test_builded_tree
    a_ary = [
      #      8                3                    10
      @tree.root.val, @tree.root.lnode.val, @tree.root.rnode.val,
      #      1                        6
      @tree.root.lnode.lnode.val, @tree.root.lnode.rnode.val,
      #      4                       7
      @tree.root.lnode.rnode.lnode.val, @tree.root.lnode.rnode.rnode.val,
      #        14                          12
      @tree.root.rnode.rnode.val, @tree.root.rnode.rnode.lnode.val,
    ]
    #
    @ary.zip(a_ary) {|expected, actual| assert_equal expected, actual }
  end

  def test_search_exist_val
    expected = true
    actual = @tree.search(6)
    assert_equal expected, actual
  end

  def test_search_non_exist_val
    expected = false
    actual = @tree.search(9)
    assert_equal expected, actual
  end

  def test_empty_tree
    assert_equal true, @tree_empty.is_empty?
    # assert_nil @tree_emtpy.root
  end

  def test_tree_with_1_node
    tree_1node = BST::Tree.new(1)
    assert_equal 1, tree_1node.node_count, "and 1 node tree should have a size of 1"
  end

  #
  # Insertion tests
  #
  def test_insert
    assert_equal @ary.sort.uniq.size, @tree.node_count

    # root is 8
    assert_equal @ary.first, @tree.root.val

    # root of first left subtree is 3
    assert_equal @ary[1], @tree.lstree.val
    # => tree.lstree is a subtree (whose root is a node)

    # root of first right subtree is 10
    assert_equal @ary[2], @tree.rstree.val
  end

  def test_insert_same_val_twice_dont_change_tree
    @ary.each { |v| @tree.insert(v) } # do it a second time...
    assert_equal @ary.sort.uniq.size, @tree.node_count
  end


  #
  # test absolute min max of a tree
  #
  def test_amin_undef_tree
    assert_nil @tree_empty.min, "empty tree has no min."
  end

  def test_amax_undef_tree
    assert_nil @tree_empty.max, "empty tree has no max."
  end

  def test_amin_defined_tree
    expected = @ary.min
    actual = @tree.min
    assert_equal expected,
                 actual,
                 "the min (here #{expected}) of a tree is leftmost leaf, got: #{actual}"
  end

  def test_amax_defined_tree
    expected = @ary.max
    actual = @tree.max
    assert_equal expected,
                 actual,
                 "the max (here #{expected}) of a tree is rightmost leaf, got: #{actual}"
  end

  #
  # traversal
  #
  def test_traversal_in_order
    expected = @ary.sort.uniq
    actual = @tree.traversal(:in)
    assert_equal expected,
                 actual,
                 "got: #{actual.inspect} but it should be #{expected.inspect}"
  end

  def test_traversal_pre_order
    expected  = [ 8, 3, 1, 6, 4, 7, 10, 14, 12]
    actual = @tree.traversal(:pre)
    assert_equal expected,
                 actual,
                 "got: #{actual.inspect} but it should be #{expected.inspect}"
  end

  def test_traversal_post_order
    expected  = [ 1, 4, 7, 6, 3, 12, 14, 10, 8 ]
    actual = @tree.traversal(:post)
    assert_equal expected,
                 actual,
                 "actual: #{actual.inspect} should be #{expected.inspect}"
  end

  #
  # supply on own function
  #
  def test_traversal_post_2x_each_entry
    expected  = [ 1, 4, 7, 6, 3, 12, 14, 10, 8 ].map {|x| x * 2}
    actual = @tree.traversal(:post, ->(x) { x * 2 })
    assert_equal expected,
                 actual,
                 "actual: #{actual.inspect} should be #{expected.inspect}"
  end

  def test_in_order_succ
    # Prep
    succ_act = @ary.map {|v| a = @tree.in_order_succ(v); a.first.is_a?(Symbol) ? :undef : a.first.val }
    succ_exp = [10, 4, 12, 3, 7, 6, 8, :undef, 14]
    exp_act  = succ_exp.zip(succ_act)
    #
    # Assert
    @ary.zip(exp_act) {|val, (exp, act)|
      assert_equal exp, act, "in-order succ of #{val} should be #{exp}, got #{act}"
    }
  end

  #
  # Deletion tests
  #
  def test_delete_leaf_node
    # so no children
    universe = [ 12 ] # [ 4, 7, 12 ]
    _delete_hlp(universe)
  end

  def test_delete_node_w_1_child
    # so no children
    universe = [ 10, 14 ]  # good 1 has rigth child, the other a left child
    _delete_hlp(universe)
  end

  def test_delete_node_w_2_children
    # code: val:succ:root
    universe = ['3:4:8', ] # [ '6:7:8', '8:10:10']
    0.upto(universe.size - 1) do |ix|
      # build the tree
      tree = BST::Tree.new
      @ary.each { |v| tree.insert(v) }
      #
      val, expected_rval, expected_root = universe[ix].split(':').map(&:to_i)
      #
      expected_count = tree.node_count - 1
      ix_val = tree.traversal(:pre).index(val)  #@ary.index(val)

      # deletion
      tree.delete(val)
      actual_count = tree.node_count
      actual_root = tree.root.val
      #
      # 1 node less
      assert_equal expected_count, actual_count,
                   "when deleting #{val.inspect} from subtree, " +
                   "should have #{expected_count} nodes, got #{actual_count}"
      #
      # what is the root
      assert_equal expected_root, actual_root,
                   "prev. root val was #{@ary.first}, with deletion of node(val=#{val})," +
                   " expected root should be: #{expected_root}, got: #{actual_root}"
      #
      # is the replacement value at the right place
      actual_rval = tree.traversal(:pre)[ix_val]
      assert_equal expected_rval, actual_rval,
                   "val deleted #{val}, which was at index #{ix_val} should now be " +
                   "#{expected_rval}, got: #{actual_rval} "
      #
      tree = nil
    end
  end

  # delete node in empty tree => NO-OP
  def test_delete_node_in_empty_tree
    @tree_empty.delete(0)
    assert_equal 0,
                 @tree_empty.node_count,
                 "deleting a node from an empty tree is a NO-OP, but got something"
  end

  # delete node from tree mono-node  (where node.val == key to delete)
  def test_delete_node_tree_mono_node
    # Prep
    tree = BST::Tree.new
    val = 10
    tree.insert(val)
    tree.delete(val)
    # Test
    exp_root, exp_count = nil, 0
    act_root, act_count = tree.root.val, tree.node_count
    #
    assert_equal exp_root, act_root
    assert_equal exp_count, act_count,
                 "deleting a node from a mono-node tree results in an empty tree, but got: #{act_count} node(s)"
  end
  
  # delete node from tree with 2 nodes (root, lnode) or (root, rnode)
  def test_delete_node_tree_l_2_nodes
    # Prep
    tree = BST::Tree.new
    val  = [10, 8]
    val.each {|v| tree.insert(v)}
    tree.delete(val.last)
    # Test
    _delete_node_tree_hlpr(val, tree)
  end

  # delete node from tree with 2 nodes (root, rnode)
  # symetric of prev.
  def test_delete_node_tree_r_2_nodes
    # Prep
    tree = BST::Tree.new
    val  = [8, 10]
    val.each {|v| tree.insert(v)}
    tree.delete(val.last)
    # Test
    _delete_node_tree_hlpr(val, tree)
  end

  def test_delete_root_node_tree_l_2_nodes
    # Prep
    tree = BST::Tree.new
    val  = [10, 8]
    val.each {|v| tree.insert(v)}
    tree.delete(val.first) # root deletion
    # Test
    _delete_root_node_tree_hlpr(val, tree)
  end

  def test_delete_root_node_tree_r_2_nodes
    # Prep
    tree = BST::Tree.new
    val  = [8, 10]
    val.each {|v| tree.insert(v)}
    tree.delete(val.first)   # root deletion
    # Test
    _delete_root_node_tree_hlpr(val, tree)
  end

  # sorted?
  def test_is_sorted
    ary = @tree.sort
    y = ary.first
    assert_equal true,
                 ary.all? {|x| y <= x ? y = x : false},
                 "expected a sorted array, got: #{ary.inspect}"
  end

  # def test_delete_tree_completely
  #   puts("==> init. tree: #{@tree.inspect}")    
  #   @tree.delete(8)
  #   puts("==> new   tree: #{@tree.inspect} // after deleting: 8")
  #   @tree.delete(3)
  #   puts("==> new   tree: #{@tree.inspect} // after deleting: 3")
  #   @tree.delete(10)
  #   puts("==> new   tree: #{@tree.inspect} // after deleting: 10")
  #   
  #   # assert_equal exp_root, act_root, "root should be #{exp_root}, got: #{act_root}"
  #   # assert_equal exp_count, act_count, "number of node should be #{exp_count}, got: #{act_count}" 
  # end
  
  def test_delete_tree_completely_off
   #puts("==> init. tree: #{@tree.inspect}")
   @ary.each {|v| @tree.delete(v)}
   exp_root, exp_count = nil, 0
   act_root, act_count = @tree.root.val, @tree.node_count
   #puts("==> final tree: #{@tree.inspect}")
   #
   assert_equal exp_root, act_root, "root should be #{exp_root}, got: #{act_root}"
   assert_equal exp_count, act_count, "number of node should be #{exp_count}, got: #{act_count}" 
  end

  def test_traversal_level_order
    # given array: @ary == [ 8, 3, 10, 1, 6, 4, 7, 14, 12]
    expected = [8, 3, 10, 1, 6, 14, 4, 7, 12]
    actual = @tree.traversal(:level)
    assert_equal expected,
                 actual,
                 "level order traversal, expected: #{expected}, got: #{actual}"
  end

  def test_height
    expected = 0
    actual = @tree_empty.height
    assert_equal expected, actual, "depth of an empty tree is #{expected.inspect}, got #{actual.inspect}"
    #
    expected1 = 4
    actual1 = @tree.height
    assert_equal expected1, actual1, "depth of an empty tree is #{expected1.inspect}, got #{actual1.inspect}"
  end

  def test_iddfs
    expected = [8, 3, 10, 1, 6, 14, 4, 7, 12]
    actual = @tree.iddfs()
    assert_equal expected,
                 actual,
                 "iddfs traversal, expected: #{expected}, got: #{actual}"
  end
  
  private
  def _delete_hlp(universe)
    ix = rand(universe.size) # 0..2
    val = universe[ix]
    # count should be decr by 1
    expected_count = @tree.node_count - 1

    # root unchanged
    expected_root = @ary.first

    # deletion
    @tree.delete(val)
    actual_count = @tree.node_count
    actual_root = @tree.root.val

    assert_equal expected_count, actual_count,
                 "when deleting #{val.inspect} [ix: #{ix}] from subtree, " +
                 "should have #{expected_count} nodes, got #{actual_count}"
    assert_equal expected_root, actual_root

    # in order traversal should give seq.
    expected = @ary.sort.uniq
    expected.delete(val) # will work because unique value - delete first occ. - Mutation
    actual   = @tree.traversal(:in)
    #
    assert_equal expected, actual,
                 "when deleting #{val.inspect} the expected seq. should be " +
                 "#{expected.inspect}, got: #{actual.inspect}"
  end

  def _delete_node_tree_hlpr(val, tree)
    exp_root, exp_count = val.first, 1
    act_root, act_count = tree.root.val, tree.node_count
    _chck_assert(exp_root, act_root, exp_count, act_count)
  end

  def _delete_root_node_tree_hlpr(val, tree)
    exp_root, exp_count = val.last, 1
    act_root, act_count = tree.root.val, tree.node_count
    _chck_assert(exp_root, act_root, exp_count, act_count)
  end
  
  def _chck_assert(exp_root, act_root, exp_count, act_count)
    assert_equal exp_count, act_count, "number of node should be #{exp_count}, got: #{act_count}"
    assert_equal exp_root, act_root, "root should be #{exp_root}, got: #{act_root}"
  end

end
