# -*- coding: utf-8 -*-
#
# file: lib/common/tree_utils.rb

module Common

  module TreeUtils

    @@id_fun = ->(x) { x }
    
    Op = Struct.new(:v) {
      def to_s; v.to_s; end
      def to_i; v.to_i; end
    }
    #
    VALID_OP = [
      LT = Op.new(-1),
      EQ = Op.new(0),
      GT = Op.new(1),
    ]    

    # for convenience
    [:lstree, :rstree].each do |meth|
      define_method(meth) do
        m = meth.to_s.sub(/stree/, 'node').to_sym
        @root.nil? ? nil : @root.send(m)
      end
    end

    def is_empty?
      @root.nil?
    end
   
    #
    # in-order (:in), pre-order(:pre), post-order(:post)
    # the supplied function cannot mutate the tree
    #
    def traversal(way=:post, lbd=@@id_fun)
      self.send("_#{way}_order".to_sym, @root, lbd)
    end    

    #
    # return an array:
    #  [ ref_to_succ_in-order(val), parent, link ] iif defined
    # or
    #  [ :undef, :undef, :undef ]
    #
    def in_order_succ(val, root=@root)
      return nil if root.nil?
      #
      # val, current node (=root), ary == [parent, gparent and link],
      _in_order_succ(val, root, [root, root, :root], nil)
    end

    #
    # return sorted array (from in-order traversal of the BST
    #
    def sort
      _in_order(@root, @@id_fun) # use Id function
    end

    #
    # iterative version using interative in-order traversal
    #
    def depth(root=@root)
      return 0 if root.nil?  # height of an empty tree is 0
      _pre_order(root, [], nil).first
    end

    #
    # original iterative version  using an iterative in-order traversal
    # we use a stack to keep track of the node, so treat rnode
    # before lnode
    # 
    def depth_iter(root=@root)
      return 0 if root.nil?  # height of an empty tree is 0
      
      s = []
      h = 1
      s.push [root, h]
      loop do
        break if s.empty?
        node, _h = s.pop
        # nothing to do with node.val
        h = _h if h < _h # interested by the max
        s.push [node.rnode, _h+1] if node.rnode
        s.push [node.lnode, _h+1] if node.lnode
      end
      h
    end
    
    def depth_rec(root=@root)
      if root.nil?
        0
      else
        dl = root.lnode ? depth_rec(root.lnode) : 0
        dr = root.rnode ? depth_rec(root.rnode) : 0
        1 + [dl, dr].max
      end      
    end

    alias_method :height, :depth
    
    def iddfs(root=@root, depth_lim=self.depth, lbd=@@id_fun)
      depth = 0
      ary = []
      loop do
        node_ary = _dls(root, depth)
        if node_ary
          node_ary.each {|node| ary << lbd.call(node.val) unless ary.include?(node.val)}      
        end
        depth += 1
        break if depth > depth_lim
      end
      ary
    end
    
    private
    alias :origin_inspect :inspect

    public
    def inspect(root=@root, lbd=@@id_fun)
      if root.nil?
        origin_inspect
      else
        #_pre_order(root, ->(v) { "#{v} " })
        _pre_order(root, lbd)
      end
    end

    #
    # Defined a fallback for non-defined (traversal) _order methods
    #
    def method_missing(meth, *args, &block)
      # method in Ruby are all lowercase...
      if meth.to_s =~ /_[a-z0-9]+_order/
        STDERR.print("[!] method #{meth} not defined yet...\n")
        Kernel.exit 1
      else
        super
      end
    end
    
    def respond_to_missing?(meth, include_private=false)
      meth.to_s =~ /_[a-z0-9]+_order/ ? false : super
    end
    
    private
    #
    # define an empty binary tree
    #
    def _init(val, klass)
      @node_count ||= 0
      @root = val ? klass.new(val) : nil
      @node_count += 1 unless val.nil?
    end

    #
    # given a node returns how many children and the link to the
    # children (if defined)
    #
    def _num_of_children(root)
      return [ 0, nil, nil ] if root.nil?
      #
      n  = root.lnode.nil? ? 0 : 1
      n += root.rnode.nil? ? 0 : 1
      [n, root.lnode, root.rnode]
    end
    
    # Depth first - recursive version
    # will apply a block (3rd implicit parms) on each node using in-order
    # traversal and collect the result into an array
    #
    def _in_order(root, ary=[], lbd)
      if root.nil?
        ary
      else
        _in_order(root.lnode, ary, lbd)
        ary << lbd.call(root.val)
        _in_order(root.rnode, ary, lbd)
      end
    end

    #
    # Depth first - iterative version
    #
    def _pre_order(root, ary=[], lbd)
      return ary if root.nil?
      #
      s, h = [], 1      
      s.push [root, h]
      ary = [ h ] if lbd.nil?
      loop do
        break if s.empty?
        node, h = s.pop
        if lbd         
          ary << lbd.call(node.val)
        elsif ary.first < h
          ary[0] = h
        end
        s.push [node.rnode, h+1] if node.rnode
        s.push [node.lnode, h+1] if node.lnode
      end
      ary      
    end    

    # Depth first - recursive    
    # return an array - _pre_order = root, left, right
    #
    def _pre_order_rec(root, ary=[], lbd)
      if root.nil?
        ary
      else
        ary << lbd.call(root.val)
        _pre_order_rec(root.lnode, ary, lbd)
        _pre_order_rec(root.rnode, ary, lbd)
      end
    end

    # Depth first
    # return an array - _post_order = root, left, right
    def _post_order(root, ary=[], lbd)
      if root.nil?
        ary
      else
        _post_order(root.lnode, ary, lbd)
        _post_order(root.rnode, ary, lbd)
        ary << lbd.call(root.val)
      end
    end

    # Breadth first, using a queue (space consumming)
    #
    def _level_order(root, ary=[], lbd)
      ary, q = [], BST::MyQueue.new
      q.enqueue root
      loop do
        break if q.empty?
        node = q.dequeue
        ary << lbd.call(node.val)
        q.enqueue node.lnode if node.lnode          
        q.enqueue node.rnode if node.rnode
      end
      ary      
    end

    def _delete_node(root, parent, link)
      return if root.nil?
      #
      n, l, r = _num_of_children(root)
      case n
      when 0
        link == :left ? parent.lnode = nil : parent.rnode = nil
        # Be careful here, node equality is defined in term of val only, what we mean here
        # Same node (same val same lnode same rnode - same internal id)
        if root.equal?(@root) # && parent == root
          _replace_node_val(@root, nil)
        end
        @node_count -= 1
      when 1
        _delete_node_1_child(root, parent, link, l, r)
      when 2
        node, p, lnk = in_order_succ(root.val, root) # == in-order node succ of root.val
        _replace_node_val(root, node.val)
        _delete_node(node, p, lnk) # delete
      else
        raise ArgumentError, "the number of node must be in [0..2], got #{n.inspect}"
      end
    end

    def _replace_node_val(o_node, val)
      o_node.send(:vmutate, val) # Cannot write o_node.val = val and do not want to...
      # ... so bypass private encapsulation (one those edge case where it is fine)
    end
    
    #
    # need to keep track of current node (=root),
    #  \ its parent and grand-parent (gparent) and link=> p_ary
    #
    def _in_order_succ(val, root, p_ary, indic)
      p, gp, _ = p_ary
      gp, p = p, root
      case Op.new(val <=> root.val)
      when EQ
        _find_succ(val, root, p_ary,  indic.nil? ? :root : indic)
      when GT
        l = :right
        _in_order_succ(val, root.rnode,
                       [p, gp, l], indic.nil? ? l : indic)
      when LT
        l = :left
        _in_order_succ(val, root.lnode,
                       [p, gp, l], indic.nil? ? l : indic)
      else
        # NO-OP
      end
    end

    #
    # Returns ary 3 items [ref_to_succ, parent_ref_to_succ, link]
    #
    def _find_succ(val, root, p_ary, indic)
      return :undef if root.nil?
      #
      if root.rnode.nil? # no right child
        _find_succ_no_rnode(val, root, p_ary, indic)
      else               # root.rnode is defined
        p, gp, _ = p_ary
        gp, p, root = p, root, root.rnode
        link = :right
        loop do          # follow left link (if it exists)
          break if root.lnode.nil?
          gp, p, root = p, root, root.lnode
          link = :left unless link == :left
        end
        [root, p, link]
      end
    end

    #
    #  Returns ary 3 items [ref_to_succ, parent_ref_to_succ, link]
    #
    def _find_succ_no_rnode(val, root, p_ary, indic)
      ary =
        case indic
        when :root
          [ :undef, :undef, :undef ] # the max of the tree is the root
          #      # (the tree has a root and a left subtree only
        when :left
          # 2 cases rightmost val of the left subtree => succ is root
          # otherwise it is the parent
          # problem how do I know that I am on the rightmost val (of the left subtree)
          # parent value should be >(= ?) to current val
          p, gp, l = p_ary
          p.val < val ? [ @root, @root, :root] : [ p, gp, l ]
        when :right
          #
          # rightmost val of the right tree is the max for which we do not have a succ
          # so if root.val is val, we are on the right most val of the right subtree
          p, gp, l = p_ary
          val < p.val ? [p, gp, l] : [:undef, :undef, :undef]
        else
          raise ArgumentError,
                "Expect indicator in the range [:root, :left, :right], got #{indic.inspect}"
        end
      ary
    end

    def _find_succ_rnode(root, parent, indic)
      parent, root = root, root.rnode
      loop do # follow left link (if it exists)
        break if root.lnode.nil?
        parent, root = root, root.lnode
      end
      parent
    end

    def _delete_node_1_child(root, parent, link, l, r)
      case link
      when :left
        parent.lnode = l || r
      when :right
        parent.rnode = l || r
      when nil
        root = @root     # change @root
        if @root.lnode
          _set_new_root_l(root)
        elsif @root.rnode
          _set_new_root_r(root)
        else
          @root = nil
        end
      end
      @node_count -= 1
    end

    def _set_new_root_l(root)
      @root = @root.lnode
      root.lnode = nil # so that root can be GC
    end
    
    def _set_new_root_r(root)
      @root = @root.rnode
      root.rnode = nil # so that root can be GC
    end

  end # of Tree::Utils

end # Common
