# -*- coding: utf-8 -*-
#
# file: lib/bst.rb

require 'common/tree_utils'

module BST

  #
  # a basic unbounded queue
  #
  class MyQueue

    def initialize(n=nil)
      @q = n.nil? ? [] : Array.new(n)
    end

    def enqueue(x)
      @q.push(x)
    end

    def dequeue
      @q.shift
    end

    def empty?
      @q.size == 0
    end

  end

  class Node
    include Comparable

    attr_reader :val
    attr_accessor :lnode, :rnode

    def initialize(val)
      @val = val
    end

    #
    # val has a type which allow Comparable
    # therefore here we just need to extend that notion to the node
    #
    def <=>(oNode)
      self.val <=> oNode.val
    end

    # TODO other properties
    def to_s
      "value: #{@val} - left: #{@lnode.inspect} / right: #{@rnode.inspect}"
    end

    private
    def vmutate(val)
      @val = val
    end

  end


  class Tree
    include Common::TreeUtils

    attr_reader :root, :node_count

    def initialize(val=nil)
      _init(val, BST::Node)
    end

    #
    # return true or false
    #
    def search(val, root=@root)
      _, _, found = _search(val, root, root, nil)
      return found
    end

    #
    # do not insert val if already in the tree!
    #
    def insert(val, root=@root)
      parent, link, found = _search(val, root, root, nil)
      #
      _create_node(val, parent, link) unless found
    end

    #
    # (!) lookup for the node to delete first (which means 2 traversal of the tree
    # 1 for the lookup and 1 for the deletion - is this acceptable?
    # yes if we are concern about separation of concern: 1 - search, 2 - manipulate the tree
    #
    # return the parent's node to delete (which is a node)
    #
    def delete(val, root=@root)
      parent, link, found = _search(val, root, root, nil)
      return if parent.nil?
      #
      # delete(current node, current's parent, link <from parent to curr>)
      n = _node_2_del(parent, link)
      _delete_node(n, parent, link) if found
    end

    #
    # min and max of a given tree
    #
    [:min, :max].each do |meth|
      define_method(meth) do
        @root.nil? ? @root : self.send("_#{meth}".to_sym).first
      end
    end

    #
    # private helpers from here
    #
    private

    def _children(root)
      return nil if root.nil?
      ary = []
      ary << root.lnode if root.lnode
      ary << root.rnode if root.rnode
      ary
    end

    def _add_node(val)
      n = Node.new(val)
      @node_count += 1
      n
    end

    def _create_node(val, root, link)
      n = _add_node(val)
      if root.nil?
        @root = n
      else
         link == :left ? root.lnode = n : root.rnode = n
      end
    end

    def _node_2_del(parent, link)
      if link.nil? # we are at the root of the tree
        parent
      elsif link == :left
        parent.lnode
      else
        parent.rnode # link == :right
      end
    end

    def _dls(node, depth)
      if depth == 0 && ! node.nil? # _num_of_children(node).first == 0 # "node is a goal"
        return [ node ]
      elsif depth > 0
        _children(node).flat_map {|child| _dls(child, depth - 1) }
      else
        nil
      end
    end

    #
    # return an array
    # [ 1 - parent node of the searched val,
    #   2 - parent link to searched node,
    #   3 - boolean (found =>  true else false) ]
    #
    def _search(val, root=@root, parent=@root, link=nil)
      if root.nil?
        [parent, link, false]
      else
        case Op.new(val <=> root.val)
        when EQ
          [parent, link, true]
        when LT
          _search(val, root.lnode, root, :left)
        when GT
          _search(val, root.rnode, root, :right)
        end
      end
    end

    def _min(root=@root, parent=@root, link=nil)
      root.lnode.nil? ?
        [ root.val, parent, link ] :
        _min(root.lnode, root, :left)
    end

    def _max(root=@root, parent=@root, link=nil)
      root.rnode.nil? ?
        [ root.val, parent, link ] :
        _max(root.rnode, root, :right)
    end        

  end # of Tree

  puts(" ==> instance method (public): #{Tree.instance_methods(false).inspect}")
  puts(" ==> instance method (public): #{Tree.instance_methods(true) - Object.instance_methods}")

end # of BST
