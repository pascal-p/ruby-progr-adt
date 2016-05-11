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

require 'splay_tree'

class TestSplayTrees < MiniTest::Unit::TestCase

  def setup
    @tree_empty = SplayTree::Tree.new
    #
    @ary = [ 8, 3, 10, 1, 6, 4, 7, 14, 12] # do not change this array
    @tree = SplayTree::Tree.new
    @ary.each { |v| @tree.insert(v) }
    #
    # @lbd = ->(x) { x } # the Id fun is the default for the traversal impl.
  end

  def teardown
    @tree = nil
    @ary = nil
  end

  def test_empty_tree
    expected = 0
    actual = @tree_empty.node_count
    assert_equal expected, actual, "an empty tree should have 0 nodes - got #{actual}"
    assert_nil @tree_empty.root, "an empty tree has an undefined root"
  end


  def test_non_empty_tree
    expected_r = @ary.first
    actual_r   = @tree.root.val
    assert_equal expected_r,
                 actual_r,
                 "expected root is #{expected_r}, got #{actual_r}"
    #
    expected_nn = @ary.size
    actual_nn = @tree.node_count
    assert_equal expected_nn,
                 actual_nn,
                 "expected numbder of nodes: #{expected_nn}, got #{actual_nn}"
  end
  
  def test_search_4
    # search for val ==> zig-zag and zig
    _search_hlp(4)    
  end  

  def test_search_7  
    # search for val ==> zig-zig and zig
    _search_hlp(7) 
  end  

  def test_search_3
    # search for val ==> zig
    val = 3
    _search_hlp(val)
    # lnode.val == 1 and rnode.val == 8
    assert_equal 1,
                 @tree.root.lnode.val
    assert_equal 8,
                 @tree.root.rnode.val
    assert_equal 6,
                 @tree.root.rnode.lnode.val    
  end

  def test_search_10
    # search for val ==> zag
    val = 10
    _search_hlp(val)
    # lnode.val == 1 and rnode.val == 8
    assert_equal 8,
                 @tree.root.lnode.val
    assert_equal 14,
                 @tree.root.rnode.val
    assert_equal 12,
                 @tree.root.rnode.lnode.val
  end  

  def test_min
    expected = @ary.min
    actual = @tree.min
    assert_equal expected,
                 actual,
                 "min of tree is supposed to be #{expected.inspect} got #{actual.inspect}"
    # root
    actual = @tree.root.val
    assert_equal expected,
                 actual,
                 "root of tree must be: #{expected.inspect}, got #{actual.inspect}"
    #
    expected = 3 # rnode == 3
    actual = @tree.root.rnode.val
    assert_equal expected,
                 actual,
                 "right node of tree must be: #{expected.inspect}, got #{actual.inspect}"
    #
    # rnode.lnode == nil
    actual = @tree.root.rnode.lnode
    assert_nil actual,
               "lnode of the rnode of root must be nil, got #{actual.inspect}"
    #
    # rnode.rnode == 8
    expected = 8
    actual = @tree.root.rnode.rnode.val
    assert_equal expected,
                 actual,
                 "rnode of the rnode of root must be: #{expected.inspect}, got #{actual.inspect}"
    #
    # rnode.rnode.lnode == 6
    expected = 6
    actual = @tree.root.rnode.rnode.lnode.val
    assert_equal expected,
                 actual,
                 "rnode of the rnode of root must be: #{expected.inspect}, got #{actual.inspect}"
  end

  def test_max
     expected = @ary.max
     actual = @tree.max
     assert_equal expected,
                  actual,
                  "max of tree is supposed to be #{expected.inspect} got #{actual.inspect}"
     # root
     actual = @tree.root.val
     assert_equal expected,
                  actual,
                  "root of tree must be: #{expected.inspect}, got #{actual.inspect}"
     #
     # rnode == nil
     actual = @tree.root.rnode
     assert_nil actual,
                "rnode of root must be nil, got #{actual.inspect}"
     #
     # lnode == 8
     expected = 10
     actual = @tree.root.lnode.val
     assert_equal expected,
                  actual,
                  "lnode of root must be: #{expected.inspect}, got #{actual.inspect}"
     #
     # lnode.rnode.val == 12
     expected = 12
     actual = @tree.root.lnode.rnode.val
     assert_equal expected,
                  actual,
                  "rnode of lnode of root must be: #{expected.inspect}, got #{actual.inspect}"
     #
     # lnode.lnode.val == 8
     expected = 8
     actual = @tree.root.lnode.lnode.val
     assert_equal expected,
                  actual,
                  "lnode of lnode of root must be: #{expected.inspect}, got #{actual.inspect}"
  end

  def test_delete_7
    val = 6 # next == 7
    # num. of nodes
    expected = @ary.size - 1
    @tree.delete(val)
    actual = @tree.node_count
    assert_equal expected,
                 actual,
                 "numbr of node is supposed to be #{expected.inspect}, got: #{actual.inspect}"
    #
    # root is supposed to be 7
    expected = 7
    actual = @tree.root.val
    assert_equal expected,
                 actual,
                 "root is supposed to be #{expected.inspect}, got #{actual.inspect}"
    #
    # root.lnode.cal == 3
    expected = 3
    actual = @tree.root.lnode.val
    assert_equal expected,
                 actual,
                 "root.lnode is supposed to be #{expected.inspect}, got #{actual.inspect}"
    #
    # root.rnode.val == 10
    expected = 8
    actual = @tree.root.rnode.val
    assert_equal expected,
                 actual,
                 "root.rnode is supposed to be #{expected.inspect}, got #{actual.inspect}"
  end
  
  private
  def _search_hlp(val)
    expected = true
    actual = @tree.search(val)
    assert_equal expected,
                 actual,
                 "expected to find #{val} in the tree, but got false"
    expected = val
    actual = @tree.root.val
    assert_equal expected,
                 actual,
                 "expected tree val(root) to be #{val}, but got #{actual.inspect}"
    
  end
  # TODO
end
