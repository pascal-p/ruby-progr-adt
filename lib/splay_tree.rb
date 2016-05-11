# -*- coding: utf-8 -*-
#
# file: lib/splay_tree.rb

require 'common/tree_utils'

module SplayTree

  #
  # Node contains a ref to a value...
  # and three references: left node, right node and parent node
  #
  class Node
    include Comparable

    attr_reader :val
    attr_accessor :lnode, :rnode, :pnode

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
      _init(val, SplayTree::Node)
    end

    #
    # return true or false
    #
    def search(val, root=@root)
      node, _, found = _search(val, root)
      _splay(root, node)
      return found
    end

    #
    # do not insert val if already in the tree!
    #
    def insert(val, root=@root, splay=false)
      node, link, found = _search(val, root)
      #
      # may change the root of the tree:
      _create_node(val, node, link) unless found
      _splay(root, node) if splay
    end

    #
    # (!) lookup for the node to delete first (which means 2 traversal of the tree
    # 1 for the lookup and 1 for the deletion - is this acceptable?
    # yes if we are concern about separation of concern: 1 - search, 2 - manipulate the tree
    #
    # return the parent's node to delete (which is a node)
    #
    def delete(val, root=@root)
      node, link, found = _search(val, root)
      #
      # delete(current node, current's parent, link <from parent to curr>)
      _delete_node(node, node.pnode, link)  if found
      _splay(root, node) # if splay
    end
    
    #
    # min and max of a given tree
    #
    [:min, :max].each do |meth|
      define_method(meth) do |root=@root|
        node = root.nil? ? root : self.send("_#{meth}".to_sym)
        _splay(root, node)
        node.val
      end
    end

    #
    # private helpers from here
    #
    private

    def _add_node(val)
      node = Node.new(val)
      @node_count += 1
      node
    end

    def _create_node(val, parent, link)
      node = _add_node(val)
      if parent.nil?
        @root = node
      else
        case link
        when :left
          parent.lnode = node
        when :right
          parent.rnode = node
        else
          STDERR.print("[!] expected link to be :left or :right, got: #{link.inspect} - Ignored.")
        end
        node.pnode = parent
      end
    end

    #
    # return an array
    # [ 1 - parent node of the searched val,
    #   2 - parent link to searched node (left or right),
    #   3 - boolean (found =>  true else false) ]
    #
    def _search(val, root=@root, ary=[])
      if root.nil?
        [ary.first, ary.last, false] # return the parent
      else
        case Op.new(val <=> root.val)
        when EQ
          [root, :none, true]        # return node itself
        when LT
          _search(val, root.lnode, [root, :left])
        when GT
          _search(val, root.rnode, [root, :right])
        end
      end
    end
   
    #
    # re-organize the tree
    #
    def _splay(root=@root, x) # x = node
      # ix = 0
      @changed = false
      while root != x do
        # break if ix > 20
        # ix += 1
        puts("\n++> root is #{inspect(root)} // x: #{x.val}") if $VERBOSE
        if x.pnode == root # zig or zag case
          _zig(root, x)
        else
          p  = x.pnode
          gp = p.pnode
          if (gp.rnode == p && p.lnode == x) ||
             (gp.lnode == p && p.rnode == x)
             puts(" - zig-zag case") if $VERBOSE
             _zig_zag(x, p, gp)
          else
            puts(" - zig-zig case") if $VERBOSE
            _zig_zig(x, p, gp)
          end
        end
        if @changed
          root = @root
          @changed = false # reset
        end
      end
    end

    #
    # x left child of the root (zig) or
    # x right child of the root (zag?)
    #
    # side-effect on @root
    #
    def _zig(root, x)
      if root.lnode == x
        puts("\tzig - left => r-rotate") if $VERBOSE
        _r_rotate(x, root)
      else
        puts("\tzig - right => l-rotate") if $VERBOSE
        _l_rotate(x, root)
      end
    end

    #
    # _zig_zag case applied when X is left child of a right child or
    #  a right child of a left child
    #
    # x has a parent and a grand-parent
    #
    def _zig_zag(x, p, gp)
      if gp.rnode == p && p.lnode == x
        # x is a left child of a right child
        puts(" -- x is a left child of a right child") if $VERBOSE
        _r_rotate(x, p)
        _l_rotate(x, gp)
      else
        # x is a right child of a left child
        puts(" -- x is a right child of a left child") if $VERBOSE
        _l_rotate(x, p)
        _r_rotate(x, gp)
      end
    end

    #
    # _zig_zig case applied when X is right child of a right child or
    #  a left child of a left child
    #
    # x has a parent and a grand-parent
    #
    def _zig_zig(x, p, gp)
      if gp.rnode == p && p.rnode == x
        # right child of a right child
        puts(" -- right child of a right child")  if $VERBOSE
        _l_rotate(p, gp)
        _l_rotate(x, p)
      else
        # left child of a left child
        puts(" -- left child of a left child")  if $VERBOSE
        _r_rotate(p, gp)
        _r_rotate(x, p)
      end
    end

    #
    #  X and Y are nodes - A, B and C (subtrees)
    #  A - set of keys <= X
    #  B - set of keys > X && <= Y
    #  C - set of keys > Y
    #
    #      Y             X
    #     / \           / \
    #    X   C   ==>   A  Y
    #   / \              / \
    #  A  B             B  C
    #
    # here, node is X, its parent is Y and gparent is P
    # need to change (at most 6 links):
    #   X.rnode.pnode (root of B to Y) and X.rnode to Y
    #   X.pnode (Y's parent = P) and Y.lnode (B)
    #   P.rnode or lnode (X) and X.pnode to (P)
    #
    def _r_rotate(x, y)
      return if x.nil? || y.nil? # x.pnode.nil?
      #
      _rotate_hlp(x, y, :right)
    end

    #
    # symetric of _r_rotate
    #
    #      Y             X
    #     / \           / \
    #    A   X   ==>   Y  C
    #       / \       / \
    #      B  C      A  B
    #
    def _l_rotate(x, y)
      return if x.nil? || x.pnode.nil?
      #
      _rotate_hlp(x, y, :left)
    end

    #
    # Possible side-effect on @root tree
    #
    def _rotate_hlp(x, y, dir=:left)
      puts("[1] ==> rotate: #{dir} - #{inspect(y)} - dir is #{dir.inspect}") if $VERBOSE
      p = y.pnode  # if it exists
      puts("[1.1] ====> parent: #{p.inspect} // y is #{y.val} // x is: #{x.val}") if $VERBOSE
      if p.nil?
        @root = x
        @changed = true
      else
        # is Y a left or right node of P?
        y.val >= p.val ? p.rnode = x : p.lnode = x
        puts("== == ==> p rnode = #{p.rnode.val}") if $VERBOSE
      end
      if dir == :right
        x.rnode.pnode = y unless x.rnode.nil? # set parent of B subtree
        y.lnode = x.rnode # B subtree
        x.rnode = y
      elsif dir == :left
        x.lnode.pnode = y unless x.lnode.nil? # set parent of B subtree
        y.rnode = x.lnode                     # B subtree
        x.lnode = y
      else
        raise ArgumentError,
              "expected dir to be :left or :right, got #{dir}"
      end
      x.pnode = p
      y.pnode = x
      puts("[2] ==> #{inspect(x)}") if $VERBOSE
    end


    # Depth first - recursive
    # return an array - _pre_order = root, left, right
    #
    def _pre_order(root, ary=[], lbd)
      if root.nil?
        ary
      else
        ary << lbd.call(root.val)
        _pre_order(root.lnode, ary, lbd)
        _pre_order(root.rnode, ary, lbd)
      end
    end
    
    def _min(root=@root)
      root.lnode.nil? ? root : _min(root.lnode)
    end
    
    def _max(root=@root)
      root.rnode.nil? ? root : _max(root.rnode)
    end        

  end # Tree

  puts(" ==> instance method (public): #{Tree.instance_methods(false).inspect}")
  puts(" ==> instance method (public): #{Tree.instance_methods(true) - Object.instance_methods}")
  
end # SplayTree
