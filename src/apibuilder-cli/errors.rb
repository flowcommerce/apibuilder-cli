require 'json'

module ApibuilderCli
    class Errors

        def Errors.getCommonPrefixLength(paths)
            if paths.length == 0
                return 0
            end

            to_match = paths[0][0]
            paths.each { |path|
                if path[0] != to_match
                    return 0
                end
            }

            tails = []
            paths.each { |path|
                if path.length == 1
                    return 1
                end
                tails << path[1..path.length]
            }
            return 1 + Errors.getCommonPrefixLength(tails)
        end

        def Errors.getOperationName(resourceName, method, path, commonLength)
            uniquePath = path[commonLength..path.length]

            pieces = uniquePath.split('/')

            named = pieces.select{ |piece| piece.length > 0 && piece[0] == ':'}.map{ |piece| piece[1..piece.length] }
            unnamed = pieces.select{ |piece| piece.length > 0 && piece[0] != ':'}

            if named.length == 0 && unnamed.length == 0
                return resourceName + '_' + method.downcase
            elsif named.length == 0
                return resourceName + '_' + method.downcase + '_' + unnamed.join('_and_')
            elsif unnamed.length == 0
                return resourceName + '_' + method.downcase + '_by_' + unnamed.join('_and_')
            end

            return resourceName + '_' + method.downcase + '_' + unnamed.join('_and_') + '_by_' + named.join('_and_')

        end

        def Errors.generateErrors(file)
            original_hash = JSON.parse(file)
            
        end
    end
end