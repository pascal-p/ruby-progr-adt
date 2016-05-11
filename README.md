# ruby-progr-adt - ADT [Abstract Data Type]

An implementation of BST [Binary Search Tree] and Splay Tree with Ruby

## Status

  splay-ing tree is performed in a bottom/up fashion:

```ruby
def _splay(root=@root, x) # x = node
  while root != x do
    if x.pnode == root # zig or zag case
     _zig(root, x)
    else
      p  = x.pnode
      gp = p.pnode
      if (gp.rnode == p && p.lnode == x) ||
         (gp.lnode == p && p.rnode == x) ||
         _zig_zag(x, p, gp)
      else
        _zig_zip(x, p, gp)
      end
    end
  end
end

def _zig(root, x)
  if root.lnode == x
    _r_rotate(root, x)
  else
    _l_rotate(root, x)
  end
end

def _zig_zag(x, p, gp)
  if gp.rnode == p && p.lnode == x
    # x is a left child of a right child
    _l_rotate(x, p)
    _r_rotate(x, gp)
  else
    # x is a right child of a left child
    _r_rotate(x, p)
    _l_rotate(x, gp)
   end
end

def _zig_zig(x, p, gp)
  if gp.rnode == p && p.rnode == x
    # right child of a right child
    _l_rotate(p, gp)
    _r_rotate(x, p)
  else
    # left child of a left child
    _r_rotate(p, gp)
    _l_rotate(x, p)
  end
end

```


## Development

TODO:
  - Self-balancing BST using AVL and Red-Black tree
  - 2-3 trees

## Source

https://github.com/pascal_p/adt.
