<template>
    <div id ="Param">
    </div>
</template>


<script>
    export default {
        name: 'Param',

        data () {
            
            return {
                UserInput :''
            }
        },

        methods: {

            GoToRoute: function() {

                this.$router.push({ 
                    name: 'paramdetails', 
                    
                    parameters: { 
                        id: this.UserInput 
                    }
                })
            }
        }
    }
</script>